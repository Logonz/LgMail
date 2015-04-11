DEBUG_LEVEL = 1;--0 Low info --1 Medium info --2 very spammy

function LgMail_OnLoad()

	this:RegisterEvent("VARIABLES_LOADED");
	this:RegisterEvent("ADDON_LOADED");

	if( DEFAULT_CHAT_FRAME ) then
		DEFAULT_CHAT_FRAME:AddMessage("LgMail v".."0.1".." loaded");
	end
	SlashCmdList["LGMAIL"] = LgMail_SlashHandler;
	SLASH_LGMAIL1 = "/lgmail"; -- Fixed by Aingnale@WorldOfWar
	SLASH_LGMAIL2 = "/lgm";
end

QueueTick = GetTime();
MAIL_SEND_TIME = 0.1; -- Not Needed really should send as fast as the server can handle it...

function LgMail_OnUpdate()
	if(table.getn(MailQueue) > 0 and GetTime() - QueueTick > MAIL_SEND_TIME) then
		MailQueuedItem();
		QueueTick = GetTime();
		LgMail_PrintDebug("QueueTick", 1);
	end
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

function MailItem(Item, Target, Subject, Body)
	Subject = Item.name.."("..Item.count..")" or Subject;
	Body = Item.name.."("..Item.count..")" or Body;
	PickupContainerItem(Item.bag,Item.slot);
	ClickSendMailItemButton();
	SendMail(Target, Subject, Body);
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
	elseif(event =="ADDON_LOADED" and arg1 == "LgMail") then
		--LgMail_Print("Addon Loaded");
		LgMail_Frame:ClearAllPoints();
		LgMail_Frame:SetParent(getglobal("MailFrame"));
		LgMail_Frame:SetPoint("TOPRIGHT","MailFrame","TOPRIGHT",275,-15);
		InitUI();
		--LgMail_Frame:Hide();
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