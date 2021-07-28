/*
======== Instructions ========
1) Go to a profession recipe page. Example: https://www.wowhead.com/alchemy
2) Open inspector
3) Go to console tab
4) Paste the following code
*/

// [Paste]
recipes = {}; // spellID => skill_levels
counter = {}; // just keep track of keys
skips   = {};

is_enchanting  = (document.location.pathname == '/enchanting');
is_mining      = (document.location.pathname == '/mining');

// Manual fixes for wowhead
manual_spell_to_item = {
  // inscription contracts
  292320: 156637, // bloodguard
  292012: 156638, // bloodshed
  292322: 156636, // oblivion
  259665: 156563  // sacrifice
};

function get_skill_levels() {
    var current_tab_name = $tabs.eq(current_tab).find('div').text();

    $('div.listview > div:visible .listview-row').each(function(i, row){
        // Is always the item link except for enchants where it is also the spell
        var $first_link  = $(row).find('td:first-child a');
        // Is always the spell link for all professions
        var $second_link = $(row).find('td:nth-child(2) a');

        var spellID = $second_link[0].href.match(/spell=[0-9]*/)[0].split('=')[1];
        var itemID;

        // Force to integer
        spellID = +spellID;

        // Try to find the itemID
        // First check manual overrides (that weren't connected properly in wowhead
        if (manual_spell_to_item[spellID]) {
            itemID = manual_spell_to_item[spellID];
        } else if (is_enchanting) {
            itemID = 0; // placeholder, since no enchants create items directly.

        // in rare cases there are enchant-like recipes in other professions
        // that do not create items. Add those to a list, but otherwise skip them.
        } else if ($first_link[0].href.indexOf('item=') == -1) {
            skips[spellID] = "Unknown item created by: " + current_tab_name + " - " + $second_link.text();
            return; // next in loop
        } else {
            itemID = $first_link[0].href.match(/item=[0-9]*/)[0].split('=')[1];
        }

        // Force to integer
        itemID = +itemID;

        var $td_div = $(row).find('td:nth-child(5) div');
        // if it doesn't have skill level information, skip it, its an invalid recipe
        if ($td_div.length == 1) {
            skips[spellID] = "Invalid recipe: " + current_tab_name + " - " + $second_link.text();
            //console.log('Invalid recipe skipped: ' + current_tab_name + ' (' + spellID + ') ' + $second_link.text());
            return; // next in loop
        }
        var arr = [];
        $td_div.last().find('span').each(function(j, span){
            arr.push($(span).text());
        });

        // ---- recipe skill-level manual fixes ----
        // TODO: if we ever find anything that needs to be tweaked
        // ---- ----

        // Pad up to length 3 with duplicates of the lowest number
        if (arr.length < 3) {
          // prefill the array with duplicates of the first value
          arr = Array(3 - arr.length).fill(arr[0]).concat(arr);
        }

        // Nearly all skills for retail show only 3 numbers in the table view
        // But 4 skill levels are usually shown on the spell detail page
        // Until they fix this bug force a 1 into the first spot
        if (arr.length < 4) {
          arr.unshift(1);
        }

        recipes[itemID] = recipes[itemID] || {}; // Maybe init
        recipes[itemID][spellID] = arr;
        // REM: all enchanting will be shoved under itemID(0)

        counter[spellID] = 1; // Keep track of how many valid recipes we've found
    });
    console.log('number recipes: ' + Object.keys(counter).length);
}

function print_skill_levels() {
    var arr = [];

    if (is_enchanting) {
        recipes = recipes[0]; // bust out of the placeholder itemID
        $.each(recipes, function(spellID, val){
            // [-spellID] = "A/B/C/D",  (enchanting only)
            arr.push('[-' + spellID + '] = "' + val.join('/') + '"');
        });
    } else {
        $.each(recipes, function(itemID, spells){
            if (Object.keys(spells).length == 1) { // 99% of cases
                var val = Object.values(spells)[0];
                // Don't use a nested table when only one spell per item
                // [itemID] = "A/B/C/D",
                arr.push('[' + itemID + '] = "' + val.join('/') + '"');
                return;
            }
            // [itemID] = { [spellID] = "A/B/C/D", [spellID] = "A/B/C/D" },
            var inner = [];
            $.each(spells, function(spellID, val){
                inner.push('[' + spellID + '] = "' + val.join('/') + '"');
            });
            arr.push('[' + itemID + '] = {' + inner.join(', ') + '}');
        });
    }
    arr.push(''); // Pad the end so we have a comma on every line
    console.log(arr.join(',\n'));

    // now print any skips
    arr = [];
    $.each(skips, function(spellID, message){
        arr.push("-- " + message + " ("+spellID+")");
    });
    if (arr.length > 0) {
        console.log(arr.join('\n'));
    }
}

// One time, make a list of all the valid tabs
current_tab = 0;
// WARNING: potentially brittle, there is currently no better selector to find the expansion tabs bar instead of the comments bar
//          there is no easy way to tell the difference between an actual expansion tab and "other" types of tabs (hard coded 9 expansions)
//          (tabs are not consistently named)
$tabs = $('ul.tabs').eq(0).find('li > a').slice(0,9);

// Only 5 tabs for mining -- ??? Is this a bug ???
if (is_mining) {$tabs = $tabs.slice(0,5);}

function main_loop() {
    // expected 9 main tabs expansion tabs worth, with 1 or more pages each.
    // Will start on latest expansion

    var $nav       = $('.listview-band-top:visible .listview-nav');
    var $next_page = $nav.find('a').eq(3);
    var $next_tab  = $tabs.eq(current_tab + 1);

    get_skill_levels();
    // DEBUGGING:
    //console.log('current-tab: ' + $tabs.eq(current_tab).find('div').text() + ' >>> ' + $nav.find('span').text());

    // Try next page first
    // REM: .data() does not necessarily update correctly
    //      always use attr()
    if ($next_page.attr('data-active') == 'yes') {
        // DEBUGGING:
        //console.log('Clicking next');
        $next_page.click();
        setTimeout(main_loop, 500); // Wait a moment to give it time to load
        return;
    } else if ($next_tab.length) {
        current_tab++;
        // DEBUGGING:
        //console.log('Clicking: ' + $next_tab.text());
        $next_tab.click();
        setTimeout(main_loop, 1000); // Wait a second to give it plenty of time to load
        return;
    }
    //console.log('done'); // DEBUGGING
    print_skill_levels();
}

// [/paste]

// run this to get all skill levels from this page's profession
main_loop();

/*
5) Wait for execution to complete, it will show progress indicator how many recipes have been scanned so far.
6) Copy paste output into lua file SkillLevelData.lua replacing relevant tradeskill section
6a) Delete any extra lines that come along with the copy. Such as "debugger eval code:125:17".
7) Startover from step 1 on the next profession page (excluding herbalism, skinning, fishing obviously)
*/
