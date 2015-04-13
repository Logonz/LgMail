DEBUG_LEVEL = 1;--0 Low info --1 Medium info --2 very spammy

function LgMail_OnLoad()

	this:RegisterEvent("VARIABLES_LOADED");
	this:RegisterEvent("ADDON_LOADED");
	this:RegisterEvent("MAIL_CLOSED");
	this:RegisterEvent("MAIL_INBOX_UPDATE");

	if( DEFAULT_CHAT_FRAME ) then
		DEFAULT_CHAT_FRAME:AddMessage("LgMail v".."0.1".." loaded");
	end
	SlashCmdList["LGMAIL"] = LgMail_SlashHandler;
	SLASH_LGMAIL1 = "/lgmail"; -- Fixed by Aingnale@WorldOfWar
	SLASH_LGMAIL2 = "/lgm";
end

QueueTick = GetTime();
MAIL_SEND_TIME = 0.1; -- Not Needed really should send as fast as the server can handle it...

OpenQueueTick = GetTime();


function LgMail_OnUpdate()
	if(table.getn(MailQueue) > 0 and GetTime() - QueueTick > MAIL_SEND_TIME) then
		MailQueuedItem();
		QueueTick = GetTime();
		LgMail_PrintDebug("QueueTick", 1);
	end
	if(GetTime() - OpenQueueTick > 0.05 and ContinuousAHMailOpening == true and ContinuousMailOpening == false) then
		OpenAHMail();
		OpenQueueTick = GetTime();
	end
	if(table.getn(DeleteQueue) > 0 and WaitForUpdate == false and ContinuousAHMailOpening == false and ContinuousMailOpening == false) then
		ProgressDeleteQueue();
	end
	if(GetTime() - OpenQueueTick > 0.05 and ContinuousAHMailOpening == false and ContinuousMailOpening == true) then
		OpenMail();
		OpenQueueTick = GetTime();
	end
end

WaitForUpdate = false;
DeleteQueue = {};
function ProgressDeleteQueue()
	Mail = DeleteQueue[1];
	table.remove(DeleteQueue, 1);
	for i = 0, GetInboxNumItems() do
		packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply = GetInboxHeaderInfo(i);
		if(Mail.sender == sender and Mail.subject == subject and hasItem == nil and money == 0) then
			DeleteInboxItem(i);
			bodyText, texture, isTakeable, isInvoice = GetInboxText(i);
			if(textCreated) then
				LgMail_Print("Deleted Mail with no Items/Money: From: "..sender.." Subject: "..subject.." Text: "..bodyText.." Left: "..table.getn(DeleteQueue));
			else
				LgMail_Print("Deleted Mail with no Items/Money: From: "..sender.." Subject: "..subject.." Left: "..table.getn(DeleteQueue));
			end
			WaitForUpdate = true;
		end
	end
end

ContinuousMailOpening = false;
function OpenMail()
	for i = 0, GetInboxNumItems() do
		packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply = GetInboxHeaderInfo(i);
		if(findEmptySlot()) then
			if(hasItem or money ~= 0) then
				name, itemTexture, count, quality, canUse = GetInboxItem(i);
				--invoiceType, itemName, playerName, bid, buyout, deposit, consignment = GetInboxInvoiceInfo(i);

				if(hasItem) then
					TakeInboxItem(i);
				end
				if(money ~= 0) then
					TakeInboxMoney(i);
				end
				Mail = {};
				Mail.subject = subject;
				Mail.sender = sender;
				table.insert(DeleteQueue, Mail);

				return;
			end
		else
			LgMail_Print("Full Inventory - Stopping");
			ContinuousMailOpening = false;
			return;
		end
	end
	LgMail_Print("--- Mail Done ---")
	ContinuousMailOpening = false;
end

ContinuousAHMailOpening = false;
function OpenAHMail()
	for i = 0, GetInboxNumItems() do
		packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply = GetInboxHeaderInfo(i);
		if(sender == "Stormwind Auction House") then
			if(findEmptySlot()) then
				name, itemTexture, count, quality, canUse = GetInboxItem(i);
				--invoiceType, itemName, playerName, bid, buyout, deposit, consignment = GetInboxInvoiceInfo(i);
				if(hasItem) then
					TakeInboxItem(i);
				end
				if(money ~= 0) then
					TakeInboxMoney(i);
				end
				if(IsAddOnLoaded("Lootlink") or ItemLinks ~= nil) then
					--LgMail_Print("Mail Opened: Item: "..GetItemLink(name).."x"..count);
				else
					--LgMail_Print("Mail Opened: Item: "..itemName.."x"..count);
				end
				return;
			else
				LgMail_Print("Full Inventory - Stopping");
				ContinuousAHMailOpening = false;
				return;
			end
		end
	end
	LgMail_Print("--- AH Mail Done ---")
	ContinuousAHMailOpening = false;
end

-------------------------------------------------------------------------------
-- Inventory modifying functions
-------------------------------------------------------------------------------

function findEmptySlot()
	for bag = 0, 4, 1 do
		if (GetBagName(bag)) then
			for item = GetContainerNumSlots(bag), 1, -1 do
				if (not GetContainerItemInfo(bag, item)) then
					return { bag=bag, slot=item };
				end
			end
		end
	end
	return nil;
end

MailQueue = {};
function MailQueuedItem()
	if(ItemSlotEmpty()) then
		local Mail = MailQueue[1];
		table.remove(MailQueue, 1);
		MailItem(Mail.Item,Mail.Target);
		LgMail_Print("Sent Item "..GetContainerItemLink(Mail.Item.bag,Mail.Item.slot).."x"..Mail.Item.count.." To: '"..Mail.Target.."'");
	end
end

function GetItemLink(name)
	local data = "";
	local _, _, w, x, y, z = string.find(ItemLinks[name]["i"], "(%d+):(%d+):(%d+):(%d+)");
	if(tonumber(x) == 0 and tonumber(y) == 0 and tonumber(z) == 0) then
		data = w;
	else
		data = w .. ":" .. x .. ":" .. y .. ":" .. z;
	end
	local sName, sLink, iQuality, iLevel, sType, sSubType, iCount = GetItemInfo(data);
	return sLink;
end

function MailItem(Item, Target, Subject, Body)
	Subject = Item.name.."("..Item.count..")" or Subject;
	Body = Item.name.."("..Item.count..")" or Body;
	PickupContainerItem(Item.bag,Item.slot);
	ClickSendMailItemButton();
	SendMail(Target, Subject, Body);
end

function LgMail_OpenAllAH()
	LgMail_Print("Opening all AH Mail");
	ContinuousAHMailOpening = true;
end

function LgMail_OpenAll()
	LgMail_Print("Opening all Mail WARNING; DELETION OF MAILS IS AFTER IT OPENS ALL!");
	ContinuousMailOpening = true;
end

function findItemSlot(itemId)
	local items = {};
	for bag = 0, 4, 1 do
		if (GetBagName(bag)) then
			for item = GetContainerNumSlots(bag), 1, -1 do
				local _,itemCount = GetContainerItemInfo(bag,item);
				local itemID, _, _, _, name = breakLink(GetContainerItemLink(bag,item));
				if (itemCount ~= nil and itemID == itemId) then
					--DEFAULT_CHAT_FRAME:AddMessage("Bag:"..bag.." slot:"..item.." ITEMID:"..itemID.." Name:"..name);
					table.insert(items, {bag=bag, slot=item, name=name, count=itemCount});
				end
			end
		end
	end
	return items;
end

function SendAllItems(itemId, Target)
	items = findItemSlot(itemId);
	local playerName = UnitName("player");
	for Index, Item in pairs(items) do
		--LgMail_Print("T:"..Target.." S:"..playerName);
		if(Target ~= playerName) then
			Mail = {};
			Mail.Target = Target;
			Mail.Item = Item;
			Mail.Sent = false;
			table.insert(MailQueue, Mail);
		end
	end
end

function ItemSlotEmpty() --Checks the frame If Item in slot return Nil
	mailFrame = getglobal("SendMailPackageButton");
	if(mailFrame:GetNormalTexture() == nil) then
		return 1;
	else
		return nil;
	end
end

-- Given a Blizzard item link, breaks it into it's itemID, randomProperty, enchantProperty, uniqueness and name
function breakLink(link)
	if (type(link) ~= 'string') then return end
	local i,j, itemID, enchant, randomProp, uniqID, name = string.find(link, "|Hitem:(%d+):(%d+):(%d+):(%d+)|h[[]([^]]+)[]]|h")
	return tonumber(itemID or 0), tonumber(randomProp or 0), tonumber(enchant or 0), tonumber(uniqID or 0), name
end

function LgMail_OnEvent(this, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
	if(event == "VARIABLES_LOADED") then
		LgMail_Print("Vars Loaded");
		SetUpRuleByID();
		--InitConfig();
	elseif(event =="ADDON_LOADED" and arg1 == "LgMail") then
		--LgMail_Print("Addon Loaded");
		LgMail_Frame:ClearAllPoints();
		LgMail_Frame:SetParent(getglobal("MailFrame"));
		LgMail_Frame:SetPoint("TOPRIGHT","MailFrame","TOPRIGHT",275,-15);
		--InitUI();
		--LgMail_Frame:Hide();
	elseif(event == "MAIL_CLOSED") then
		ContinuousAHMailOpening = false;
		ContinuousMailOpening = false;
		DeleteQueue = {};
	elseif(event == "MAIL_INBOX_UPDATE") then
		WaitForUpdate = false;
	end
end
function LgMail_MailAll()
		MailQueue = {};
		LgMail_Print("-- Mail All Used --");
		--LgMail_Print("RuleSize: "..table.getn(MassSendRules));
		for Index, RuleSubset in pairs(MassSendRules) do
			local Name = RuleSubset.Name;
			--LgMail_Print("Started MailAll : Trying:"..Name);
			for ItemIndex, ItemId in pairs(RuleSubset.Items) do
				--LgMail_Print("Trying to send Itemid:"..ItemId.." To: "..Name);
				SendAllItems(ItemId, Name);
			end
		end
		if(table.getn(MailQueue) == 0) then
			LgMail_Print("-- Nothing to send --");
		end
end

function LgMail_SlashHandler(msg)
	if (msg=="show" or msg=="hide") then msg = ""; end
	if (not msg or msg=="") then
		--Base command
		LgMail_Print("SlashCommand Used");
	end

	if(msg == "test") then
		packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply = GetInboxHeaderInfo(1);
		Mail = {};
		Mail.subject = subject;
		Mail.sender = sender;
		table.insert(DeleteQueue, Mail);
	end

	if(msg == "init") then
		InitConfig();
	end

	if(msg == "cfg") then
		cfg = getglobal("LgMailConfigFrame");
		if(cfg:IsShown()) then
			cfg:Show();
		else
			cfg:Hide();
		end
	end

	if(msg == "OpenAll") then
		ContinuousMailOpening = true;
	end

	if(msg == "MailAll") then
		MailAll();
	end
end

function LgMail_PrintDebug(message, level) --0 Low info --1 Medium info --2 very spammy
	level = 2 or level;
	if(DEBUG_LEVEL >= level) then
		DEFAULT_CHAT_FRAME:AddMessage("[LgMail-D]: "..message,1,1,0);
	end
end

function LgMail_Print(message)
		DEFAULT_CHAT_FRAME:AddMessage("[LgMail]: "..message,1,1,0);
end


local function LgMailAddOwners(frame, id)
	if not(frame and id and MassMailRuleByID[id]) then return end

	frame:AddLine("Mail: "..MassMailRuleByID[id], 1, 0.5, 0.5);

	frame:Show()
end

MassMailRuleByID = {};
function SetUpRuleByID()
	for k, v in pairs(MassSendRules) do
		for indx, itemId in pairs(v.Items) do
			MassMailRuleByID[itemId] = v.Name;
		end
	end
end

local function LinkToID(link)
	if link then
		local _, _, id = string.find(link, "(%d+):")
		return tonumber(id)
	end
end


--[[  Function Hooks ]]--

local Blizz_GameTooltip_SetBagItem = GameTooltip.SetBagItem
GameTooltip.SetBagItem = function(self, bag, slot)
	Blizz_GameTooltip_SetBagItem(self, bag, slot)

	LgMailAddOwners(self, LinkToID(GetContainerItemLink(bag, slot)))
end

local Bliz_GameTooltip_SetLootItem = GameTooltip.SetLootItem
GameTooltip.SetLootItem = function(self, slot)
	Bliz_GameTooltip_SetLootItem(self, slot)

	LgMailAddOwners(self, LinkToID(GetLootSlotLink(slot)))
end

local Bliz_SetHyperlink = GameTooltip.SetHyperlink
GameTooltip.SetHyperlink = function(self, link, count)
	Bliz_SetHyperlink(self, link, count)

	LgMailAddOwners(self, LinkToID(link))
end

local Bliz_ItemRefTooltip_SetHyperlink = ItemRefTooltip.SetHyperlink
ItemRefTooltip.SetHyperlink = function(self, link, count)
	Bliz_ItemRefTooltip_SetHyperlink(self, link, count)

	LgMailAddOwners(self, LinkToID(link))
end

local Bliz_GameTooltip_SetLootRollItem = GameTooltip.SetLootRollItem
GameTooltip.SetLootRollItem = function(self, rollID)
	Bliz_GameTooltip_SetLootRollItem(self, rollID)

	LgMailAddOwners(self, LinkToID(GetLootRollItemLink(rollID)))
end

local Bliz_GameTooltip_SetAuctionItem = GameTooltip.SetAuctionItem
GameTooltip.SetAuctionItem = function(self, type, index)
	Bliz_GameTooltip_SetAuctionItem(self, type, index)

	LgMailAddOwners(self, LinkToID(GetAuctionItemLink(type, index)))
end