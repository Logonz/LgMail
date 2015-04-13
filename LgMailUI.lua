


DELTA_OFFSET = 0;
UIInitialized = false;
function InitUI()
	--MailItem1Button
	--<CheckButton name="btm_BroadcastCheckbox" inherits="OptionsCheckButtonTemplate" framestrata="HIGH"  checked="false">
	if(UIInitialized == false) then
		for i = 0, 7 do 
			checkbutton = CreateFrame("CheckButton", "LgMailMailItem"..i.."CB", getglobal("MailFrame"), "OptionsCheckButtonTemplate");
			 --getglobal("MailItem"..i.."Button")
			checkbutton:ClearAllPoints();
			checkbutton:SetParent(getglobal("MailFrame"));
			checkbutton:SetPoint("TOPRIGHT","MailFrame","MailItem"..i.."Button",-10,0);
		end
		UIInitialized = true;
	end
end

-------------------------------------------------------------------------------
-- An item in the list is moused over.
-------------------------------------------------------------------------------
function ListItem_OnEnter()
	--LgMail_Print(this:GetName().."Column1");
	--LgMail_Print(getglobal(this:GetName().."Column1"):GetText());
	local sName, sLink, iQuality, iLevel, sType, sSubType, iCount = GetItemInfo(getglobal(this:GetName().."Column1"):GetText());
	if (sLink) then
		GameTooltip:SetOwner(this, "ANCHOR_CURSOR");
		GameTooltip:SetHyperlink(sLink);
		GameTooltip:Show();
	end
end


function LgMailDropDown_OnLoad()
	level = level or 1 --drop down menues can have sub menues. The value of level determines the drop down sub menu tier

	for k, v in pairs(MassSendRules) do
		local info = UIDropDownMenu_CreateInfo();
		info.text = v.ListName; --the text of the menu item
		info.value = k; -- the value of the menu item. This can be a string also.
		info.func = LgMailDropDown_OnClick; --sets the function to execute when this item is clicked
		info.owner = this:GetParent(); --binds the drop down menu as the parent of the menu item. This is very important for dynamic drop down menues.
		info.checked = nil; --initially set the menu item to being unchecked with a yellow tick
		info.icon = nil; --we can use this to set an icon for the drop down menu item to accompany the text
		UIDropDownMenu_AddButton(info, level); --Adds the new button to the drop down menu specified in the UIDropDownMenu_Initialise function. In this case, it's MyDropDownMenu
	end
	DELTA_OFFSET = 0;
end

-------------------------------------------------------------------------------
-- Returns the item color for the specified result
-------------------------------------------------------------------------------
function AuctionFrameSearch_GetItemColor(quality)
	if (quality) then
		return ITEM_QUALITY_COLORS[quality];
	end
	return { r = 1.0, g = 1.0, b = 1.0 };
end

function PopulateList(RuleIndex)
	for i = 1, LOG_LINES do
		--local linefr = getglobal("LgMailLine"..i);
		local Column1 = getglobal("LgMailLine"..i.."Column1");
		local Column2 = getglobal("LgMailLine"..i.."Column2");
		Column1:SetText("");
		Column2:SetText("");
		--linefr:Hide();
	end
	local items = MassSendRules[RuleIndex].Items;
	for i = 1, table.getn(MassSendRules[RuleIndex].Items) do
		local indx = DELTA_OFFSET + i
		if(items[indx]) then
			local sName, sLink, iQuality, iLevel, sType, sSubType, iCount = GetItemInfo(items[indx]);
			if(i <= LOG_LINES) then
				--local linefr = getglobal("LgMailLine"..k);
				local Column1 = getglobal("LgMailLine"..i.."Column1");
				local Column2 = getglobal("LgMailLine"..i.."Column2");
				Column1:SetText(items[indx]);
				if(sName and iQuality) then
					Column2:SetText(AuctionFrameSearch_GetItemColor(iQuality).hex..sName);
				else
					Column2:SetText("|cffff0000Server Query failed|r");
				end
				--Column2:SetText(sLink);
				--linefr:Show();
			else
				break;
			end
		end
	end
end

function ScrollList(delta)
	DELTA_OFFSET = DELTA_OFFSET - delta;
	if(DELTA_OFFSET < 0) then
		DELTA_OFFSET = 0;
	end
	ResetSelection();
	PopulateList(DropDownIndex);
end

DropDownIndex = 0;
function LgMailDropDown_OnClick() 
	UIDropDownMenu_SetSelectedValue(this.owner, this.value); 
	PopulateList(this.value)
	DropDownIndex = this.value;
end

SELECTED_ITEM = "";
function ToggleHighlight(Frame)
	ResetSelection();
	Frame:LockHighlight();
	SELECTED_ITEM = Frame;
	LgMail_Print("Index:"..Frame:GetName());
end

function ResetSelection()
	for i = 1, LOG_LINES do
		line = getglobal("LgMailLine"..i);
		line:UnlockHighlight();
	end

end

function GetSelectedListItem()
	for i = 1, LOG_LINES do
		line = getglobal("LgMailLine"..i);
		if(line:GetNormalTexture() ~= nil) then
			LgMail_Print("Selected line: "..i);
			return i;
		end
	end
end

LOG_LINES = 16;
HIGHLIGHTTEXTURE = "Interface\\HelpFrame\\HelpFrameButton-Highlight";
UIInitialized = false;
function InitConfig()
	LgMail_Print("Loading Cfg window");
	CFGFrame = CreateFrame("Frame", "LgMailConfigFrame", UIParent);
	CFGFrame:SetFrameStrata("BACKGROUND");
	CFGFrame:SetWidth(500);
	CFGFrame:SetHeight(500);

	CFGFrame:SetBackdrop( { 
	  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
	  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, 
	  insets = { left = 11, right = 12, top = 12, bottom = 11 }
	});

	--CFGFrame:EnableMouseWheel(true);
	--CFGFrame:SetScript("OnMouseWheel", function() 
	--	LgMail_Print(DELTA_OFFSET);
	--	DELTA_OFFSET = DELTA_OFFSET + arg1;
	--end);

	CFGFrame:SetPoint("CENTER",0,0);
	CFGFrame:Show();

	CFGFrame.LogFrame = CreateFrame("Frame", "LgMailConfigListFrame", CFGFrame);
	CFGFrame.LogFrame:SetFrameStrata("BACKGROUND");
	CFGFrame.LogFrame:SetWidth(500);
	CFGFrame.LogFrame:SetHeight(500);

	CFGFrame.LogFrame:SetBackdrop( { 
	  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
	  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, 
	  insets = { left = 11, right = 12, top = 12, bottom = 11 }
	});

	CFGFrame.LogFrame:SetPoint("CENTER",0,0);

	CFGFrame.LogFrame:Show();

	--asdf = CreateFrame("Button", "LgMailLine"..1, CFGFrame, "LgMailListItemTemplate");
	--asdf:SetText("ItemName");
	--asdf:SetWidth(300);
	--asdf:SetHeight(26);
	--getglobal("LgMailLine".."1".."Column1"):SetText("HEJ");
	--asdf:SetHighlightTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight", "ADD");
	--asdf:SetPoint("CENTER",0,0);
	--asdf:Show()

	CFGFrame.DropDown = CreateFrame("Frame", "LgMailDropDownMenu", CFGFrame, "UIDropDownMenuTemplate");
	CFGFrame.DropDown:SetPoint("TOPLEFT", CFGFrame, "TOPLEFT", 10, -20)
	UIDropDownMenu_SetWidth(130, CFGFrame.DropDown);
	UIDropDownMenu_Initialize(CFGFrame.DropDown, LgMailDropDown_OnLoad);
	CFGFrame.DropDown:Show();

	--CFGFrame.EditListNameBox = CreateFrame("Editbox", "LgMailEditListNameBox", CFGFrame, "InputBoxTemplate");
	--CFGFrame.EditListNameBox:SetPoint("TOPLEFT", CFGFrame, "TOPLEFT", 10, -30)
	--CFGFrame.EditListNameBox:SetText("EDIT TEXT");
	--CFGFrame.EditListNameBox:Show();

	CFGFrame.LogFrame.LineFrames = {}
	CFGFrame.LogFrame.ItemID = {}
	CFGFrame.LogFrame.Lines = {}
	for i=1, LOG_LINES do
		CFGFrame.LogFrame.LineFrames[i] = CreateFrame("Frame", "LgMailScanLogFrame"..i, CFGFrame.LogFrame)

		if (i == 1) then
			CFGFrame.LogFrame.LineFrames[i]:SetPoint("TOPLEFT", CFGFrame.LogFrame, "TOPLEFT", 10, -20)
			CFGFrame.LogFrame.LineFrames[i]:SetPoint("RIGHT", CFGFrame.LogFrame, "RIGHT", -20, 0)
		else
			CFGFrame.LogFrame.LineFrames[i]:SetPoint("TOPLEFT", CFGFrame.LogFrame.LineFrames[i-1], "BOTTOMLEFT")
			CFGFrame.LogFrame.LineFrames[i]:SetPoint("RIGHT", CFGFrame.LogFrame.LineFrames[i-1], "RIGHT")
		end
		CFGFrame.LogFrame.LineFrames[i]:SetHeight(16)
		CFGFrame.LogFrame.LineFrames[i]:SetWidth(300);
		CFGFrame.LogFrame.LineFrames[i].lineID = i
		CFGFrame.LogFrame.LineFrames[i]:EnableMouse(true)
		--CFGFrame.LogFrame.LineFrames[i]:SetScript("OnEnter", InitConfig) --Script Toolip
		--CFGFrame.LogFrame.LineFrames[i]:SetScript("OnLeave", InitConfig) --Script Exit Tooltip

		--CFGFrame.LogFrame.ItemID[i] = CFGFrame.LogFrame.LineFrames[i]:CreateFontString("BtmScanLogDate"..i, "HIGH")
		--CFGFrame.LogFrame.ItemID[i]:SetPoint("TOPLEFT", CFGFrame.LogFrame.LineFrames[i], "TOPLEFT")
		--CFGFrame.LogFrame.ItemID[i]:SetWidth(90)
		--CFGFrame.LogFrame.ItemID[i]:SetFont("Fonts\\FRIZQT__.TTF",11)
		--CFGFrame.LogFrame.ItemID[i]:SetJustifyH("LEFT")
		--CFGFrame.LogFrame.ItemID[i]:SetText("ItemID"..i)
		--CFGFrame.LogFrame.ItemID[i]:Show()

		CFGFrame.LogFrame.Lines[i] = CreateFrame("Button", "LgMailLine"..i, CFGFrame, "LgMailListItemTemplate");
		CFGFrame.LogFrame.Lines[i]:SetText("ItemName");
		CFGFrame.LogFrame.Lines[i]:SetWidth(300);
		CFGFrame.LogFrame.Lines[i]:SetScript("OnEnter", ListItem_OnEnter) --Script Toolip
		CFGFrame.LogFrame.Lines[i]:SetScript("OnLeave", function() if(GameTooltip) then GameTooltip:Hide() end end) --Script Exit Tooltip
		--CFGFrame.LogFrame.Lines[i]:SetNormalTexture(CFGFrame.LogFrame.Lines[i]:GetHighlightTexture());
		CFGFrame.LogFrame.Lines[i]:SetScript("OnClick", function() 
			ToggleHighlight(this);
		end);
		CFGFrame.LogFrame.Lines[i]:EnableMouseWheel(true);
		CFGFrame.LogFrame.Lines[i]:SetScript("OnMouseWheel", function() 
			ScrollList(arg1);
		end);
		--CFGFrame.LogFrame.Lines[i]:SetHeight(26);
		--getglobal("LgMailLine".."1".."Column1"):SetText("HEJ");
		--CFGFrame.LogFrame.Lines[i]:SetHighlightTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight", "ADD");
		--CFGFrame.LogFrame.Lines[i]:SetPoint("CENTER",0,0);
		CFGFrame.LogFrame.Lines[i]:SetPoint("RIGHT", CFGFrame.LogFrame.LineFrames[i], "RIGHT")
		CFGFrame.LogFrame.Lines[i]:Show()

		--CFGFrame.LogFrame.Lines[i] = CFGFrame.LogFrame.LineFrames[i]:CreateFontString("BtmScanLogLine"..i, "HIGH")
		--CFGFrame.LogFrame.Lines[i] = CreateFrame("Button", "LgMailLine"..i, CFGFrame.LogFrame.LineFrames[i], "ListItemTemplate")
		--CFGFrame.LogFrame.Lines[i]:SetFont("Fonts\\FRIZQT__.TTF",11)
		-- CFGFrame.LogFrame.Lines[i]:SetPoint("TOPLEFT", CFGFrame.LogFrame.ItemID[i], "TOPRIGHT", 5, 0)
		--CFGFrame.LogFrame.Lines[i]:SetJustifyH("LEFT")
		--CFGFrame.LogFrame.Lines[i]:SetText("ItemName"..i)
		--CFGFrame.LogFrame.Lines[i]:SetHighlightTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight", "ADD");
		--CFGFrame.LogFrame.Lines[i]:Show()
	end
	CFGFrame.LogFrame.ScrollFrame = LgMailScrollBar;
	CFGFrame.LogFrame:Hide();
end

--		<HighlightTexture name="$parentHighlight" file="Interface\HelpFrame\HelpFrameButton-Highlight" alphaMode="ADD">
--			<Anchors>
--				<Anchor point="TOPLEFT">
--					<Offset>
--						<AbsDimension x="0" y="0"/>
--					</Offset>
--				</Anchor>
--				<Anchor point="BOTTOMRIGHT" relativePoint="BOTTOMRIGHT">
--					<Offset>
--						<AbsDimension x="0" y="0"/>
--					</Offset>
--				</Anchor>
--			</Anchors>
--			<TexCoords left="0" right="1.0" top="0" bottom="0.578125"/>
--		</HighlightTexture>