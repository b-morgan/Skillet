--[[

Skillet: A tradeskill window replacement.
Copyright (c) 2007 Robert Clark <nogudnik@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

]]--

-- If you are doing localization and would like your name added here, please feel free
-- to do so, or let me know and I will be happy to add you to the credits
-- Korean translation by Next96 :)

local L = LibStub("AceLocale-3.0"):NewLocale("Skillet", "koKR")
if not L then return end

L["About"] = "정보"
L["ABOUTDESC"] = "Skillet 정보 표시"
L["alts"] = "다른 캐릭터"
L["Appearance"] = "보기"
L["APPEARANCEDESC"] = "Skillet 보기 설정"
L["bank"] = "은행"
L["Blizzard"] = "블리자드"
L["buyable"] = "구매가능"
L["Buy Reagents"] = "재료 구매"
L["By Difficulty"] = "숙련도"
L["By Item Level"] = "아이템레벨"
L["By Level"] = "레벨"
L["By Name"] = "이름"
L["By Quality"] = "품질"
L["By Skill Level"] = "숙련도"
L["can be created from reagents in your inventory"] = "가방에 있는 재료로 제작할 수 있음"
L["can be created from reagents in your inventory and bank"] = "가방과 은행에 있는 재료료 제작할 수 있음"
L["can be created from reagents on all characters"] = "모든 캐릭터에 있는 재료로 제작할 수 있음"
L["Clear"] = "초기화"
L["click here to add a note"] = "클릭하면 메모를 남길 수 있습니다."
L["Collapse all groups"] = "모든 그룹 축소" -- Needs review
L["Config"] = "설정"
L["CONFIGDESC"] = "Skillet 설정을 엽니다."
L["Could not find bag space for"] = "가방에 빈공간이 없습니다."
L["craftable"] = "제작가능"
L["Crafted By"] = "제작자"
L["Create"] = "제작"
L["Create All"] = "전부 제작"
L[" days"] = " 일"
L["Delete"] = "삭제"
L["DISPLAYREQUIREDLEVELDESC"] = "제작템의 최소 요구 레벨을 표시합니다. (제조법의 앞에 표시)"
L["DISPLAYREQUIREDLEVELNAME"] = "요구 레벨 표시"
L["DISPLAYSGOPPINGLISTATAUCTIONDESC"] = "경매창에 제작에 필요한 재료를 쇼핑리스트를 표시합니다."
L["DISPLAYSGOPPINGLISTATAUCTIONNAME"] = "경매창에 쇼핑리스트 표시"
L["DISPLAYSHOPPINGLISTATBANKDESC"] = "은챙창에 제작에 필요한 재료를 쇼핑리스트에 표시합니다."
L["DISPLAYSHOPPINGLISTATBANKNAME"] = "은행창에 쇼핑리스트 표시"
L["DISPLAYSHOPPINGLISTATGUILDBANKDESC"] = "가방에는 없지만 제조법을 보고 제작할 때 필요한 아이템을 쇼핑리스트에 표시합니다."
L["DISPLAYSHOPPINGLISTATGUILDBANKNAME"] = "길드은행에서 쇼핑리스트를 표시합니다."
L["Enabled"] = "가능"
L["Enchant"] = "마법부여"
L["ENHANCHEDRECIPEDISPLAYDESC"] = "가능하면 제조법 이름에 제조법의 숙련도도 표시됩니다."
L["ENHANCHEDRECIPEDISPLAYNAME"] = "글자로 숙련도 표시"
L["Expand all groups"] = "모든 그룹 확장" -- Needs review
L["Features"] = "기능"
L["FEATURESDESC"] = "Skillet 기능 설정"
L["Filter"] = "필터링"
L["Glyph "] = "문양 "
L["Gold earned"] = "금전 획득"
L["Grouping"] = "분류"
L["have"] = "소지" -- Needs review
L["Hide trivial"] = "회색 제작템 숨기기"
L["Hide uncraftable"] = "제작할 수 없는 아이템 숨기기"
L["Include alts"] = "다른캐릭터 포함"
L["Include guild"] = "Include guild"
L["Inventory"] = "인벤토리"
L["INVENTORYDESC"] = "인벤토리 정보"
L["is now disabled"] = "is now disabled"
L["is now enabled"] = "is now enabled"
L["Library"] = "라이브러리"
L["LINKCRAFTABLEREAGENTSDESC"] = "현재 제조법에 필요한 다른 재료를 클릭하면 자동으로 제작합니다."
L["LINKCRAFTABLEREAGENTSNAME"] = " 다른 재료 클릭으로 제작"
L["Load"] = "불러옴"
L["Merge items"] = "Merge items"
L["Move Down"] = "아래로 이동"
L["Move to Bottom"] = "화면 아래로 이동"
L["Move to Top"] = "화면 위로 이동"
L["Move Up"] = "위로 이동"
L["need"] = "필요" -- Needs review
L["No Data"] = "데이터 없음"
L["None"] = "없음"
L["No such queue saved"] = "저장된 예약을 찾을 수 없습니다."
L["Notes"] = "메모"
L["not yet cached"] = "캐쉬가 없습니다."
L["Number of items to queue/create"] = "에약/제작 가능한 갯수"
L["Options"] = "설정"
L["Order by item"] = "Order by item"
L["Pause"] = "중지"
L["Process"] = "진행"
L["Purchased"] = "구매"
L["Queue"] = "예약"
L["Queue All"] = "전부 예약"
L["QUEUECRAFTABLEREAGENTSDESC"] = "현재 제조법에 필요한 다른 재료를 클릭 예약하여 자동으로 제작합니다."
L["QUEUECRAFTABLEREAGENTSNAME"] = "다른 재료 예약 제작"
L["QUEUEGLYPHREAGENTSDESC"] = "현재 제조법에 다른 재료가 필요하고, 재료가 충분하지 않으면, 재료를 만들 수 있도록 예약 설정을 합니다. 이 설정은 문양에 한합니다."
L["QUEUEGLYPHREAGENTSNAME"] = "문양 재료 예약"
L["Queue is empty"] = "예약된 것이 없습니다."
L["Queue is not empty. Overwrite?"] = "예약이 되어있습니다. 덮어씌우시겠습니까?"
L["Queues"] = "예약"
L["Queue with this name already exsists. Overwrite?"] = "예약 저장 이름이 겹칩니다. 덮어씌우시겠습니까?"
L["Reagents"] = "시약" -- Needs review
L["reagents in inventory"] = "가방에 있는 재료로 제작"
L["Really delete this queue?"] = "현재 예약을 삭제하시겠습니까?"
L["Rescan"] = "재조사"
L["Reset"] = "초기화" -- Needs review
L["RESETDESC"] = "Skillet 위치 초기화" -- Needs review
L["Retrieve"] = "회수"
L["Save"] = "저장"
L["Scale"] = "크기"
L["SCALEDESC"] = "전문기술 창의 크기를 설정합니다.(기본값:1.0)"
L["Scan completed"] = "조사가 완료되었습니다."
L["Scanning tradeskill"] = "전문기술 조사"
L["Selected Addon"] = "선택한 애드온"
L["Select skill difficulty threshold"] = "숙련도 증가 선택"
L["Sells for "] = "Sells for "
L["Shopping List"] = "쇼핑 리스트"
L["SHOPPINGLISTDESC"] = "쇼핑 리스트를 표시합니다."
L["SHOWBANKALTCOUNTSDESC"] = "제작 아이템 수량을 계산하여 보여줄 때, 다른 캐릭터의 은행에 소지하고 있는 아이템도 포함하여 표시합니다."
L["SHOWBANKALTCOUNTSNAME"] = "다른 캐릭터의 은행아이템도 포함"
L["SHOWCRAFTCOUNTSDESC"] = "제작 가능한 수량을 표시합니다. 총 가능한 수량은 아닙니다."
L["SHOWCRAFTCOUNTSNAME"] = "제작 수량 보기"
L["SHOWCRAFTERSTOOLTIPDESC"] = "아이템의 툴팁에 제작이 가능한 부캐릭터들을 표시합니다."
L["SHOWCRAFTERSTOOLTIPNAME"] = "툴팁에 제작자 표시"
L["SHOWDETAILEDRECIPETOOLTIPDESC"] = "전문기술 창에 마우스를 가져다 대면 상세 풀팁을 표시합니다."
L["SHOWDETAILEDRECIPETOOLTIPNAME"] = "제조법의 상세 툴팁 표시"
L["SHOWFULLTOOLTIPDESC"] = "제작에 필요한 모든 정보를 툴팁에 표시합니다. 설정을 끄면 제작에 필요한 정보만 표시합니다. (CTRL키를 누르면 모든 정보가 표시됩니다."
L["SHOWFULLTOOLTIPNAME"] = "일반 툴팁 사용"
L["SHOWITEMNOTESTOOLTIPDESC"] = "재료나 제작템에 사용자의 툴팁을 적을 수 있습니다."
L["SHOWITEMNOTESTOOLTIPNAME"] = "사용자 툴팁 추가"
L["SHOWITEMTOOLTIPDESC"] = "가능하다면 제작된 아이템의 툴팁을 표시합니다."
L["SHOWITEMTOOLTIPNAME"] = "아이템의 툴팁 표시"
L["Skillet Trade Skills"] = "Skillet 전문기술"
L["Skipping"] = "넘김" -- Needs review
L["Sold amount"] = "Sold amount"
L["SORTASC"] = "높은 숙련도"
L["SORTDESC"] = "낮은 숙련도"
L["Sorting"] = "정렬"
L["Source:"] = "제공자:"
L["STANDBYDESC"] = "Toggle standby mode on/off"
L["STANDBYNAME"] = "standby"
L["Start"] = "시작"
L["Supported Addons"] = "지원가능 애드온"
L["SUPPORTEDADDONSDESC"] = "지원되는 애드온에서 아이템의 갯수를 표시합니다."
L["This merchant sells reagents you need!"] = "이 상인은 제작에 필요한 재료를 판매하고 있습니다."
L["Total Cost:"] = "총 비용:"
L["Total spent"] = "총 소비"
L["Trained"] = "배움"
L["TRANSPARAENCYDESC"] = "전문기술 창의 투명도를 조정합니다."
L["Transparency"] = "투명도"
L["Unknown"] = "알 수 없음"
L["VENDORAUTOBUYDESC"] = "재료가 부족할 경우 상인을 만나면 자동으로 필요한 만큼의 재료를 구매합니다."
L["VENDORAUTOBUYNAME"] = "재료 자동 구매"
L["VENDORBUYBUTTONDESC"] = "재료가 부족할 때 상인을 만나면 구매할 수 있는 버튼을 표시합니다."
L["VENDORBUYBUTTONNAME"] = "상인에게 구매 버튼 표시"
L["View Crafters"] = "제작자 보기" -- Needs review

