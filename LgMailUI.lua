


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