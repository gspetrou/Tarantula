trn.Building = trn.Building or {}

local PANEL = {}
PANEL.PropList = {}
local bubble = surface.GetTextureID("vgui/tarantula/bubble")
PANEL.Creation = 0

function PANEL:Init()
    self:SetTitle("")
    self:MakePopup()
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self.CategoryIcon = {}
    self.Creation = CurTime() + 0.25

    for k, v in pairs(trn.Building.Classes) do
        local fl = util.JSONToTable(file.Read("spawnlist/" .. v .. ".txt") or "[]")
        self.CategoryIcon[v] = Material("props/" .. v .. ".png")
        self.PropList[v] = fl
    end

    self.Categories = {}
    self.LocalIcons = {}
    local i = 0

    for k, v in pairs(self.PropList) do
        self.Categories[k] = vgui.Create("DButton", self)
        self.Categories[k]:SetSize(2, 2)
        self.Categories[k]:SizeTo(128, 128, 0.2)
        self.Categories[k]:SetPos(ScrW() / 2 - 64, ScrH() / 2 - 64)
        self.Categories[k]:MoveTo(ScrW() / 2 + math.cos((i / 5) * math.pi * 2) * 128 - 64, ScrH() / 2 + math.sin((i / 5) * math.pi * 2) * 128 - 64, 0.25, 0)
        self.Categories[k].FPos = {ScrW() / 2 + math.cos((i / 5) * math.pi * 2) * 128 - 64, ScrH() / 2 + math.sin((i / 5) * math.pi * 2) * 128 - 64}
        self.Categories[k].Angle = (i / 5) * math.pi * 2
        self.Categories[k]:SetText("")

        self.Categories[k].Paint = function(s, w, h)
            surface.SetMaterial(self.CategoryIcon[k])
            surface.SetDrawColor(Color(255, 255, 255, (s:IsHovered() or s == self.Selected) and 255 or 100))
            surface.DrawTexturedRect(0, 0, w, h)
        end

        self.Categories[k].DoClick = function(s)
            self.Selected = s

            for _, categories in pairs(self.Categories) do
                if (categories ~= self.Selected) then
                    categories:SizeTo(96, 96, 0.2)
                else
                    categories:SizeTo(128, 128, 0.2)
                end
            end

            for _, icon in pairs(self.LocalIcons) do
                icon:Remove()
            end

            self.LocalIcons = {}

            for ik, prop in pairs(v) do
                self.LocalIcons[ik] = vgui.Create("DModelPanel", self)
                self.LocalIcons[ik]:SetModel(prop.path)
                self.LocalIcons[ik].Price = prop.price
                self.LocalIcons[ik]:SetSize(2, 2)
                self.LocalIcons[ik]:SizeTo(128, 128, 0.2)
                self.LocalIcons[ik].Parent = s
                self.LocalIcons[ik].oPaint = self.LocalIcons[ik].Paint

                self.LocalIcons[ik].DoClick = function()
                    net.Start("trn.Building.AskProp")
                    net.WriteString(k)
                    net.WriteInt(ik, 16)
                    net.SendToServer()
                    self:Remove()
                end

                self.LocalIcons[ik].OnCursorEntered = function(se)
                    se:SizeTo(196, 196, 0.25)
                    se.HoveredAt = CurTime() + 0.1
                end

                self.LocalIcons[ik].OnCursorExited = function(se)
                    se:SizeTo(128, 128, 0.25)
                    se.HoveredAt = -1
                end

                self.LocalIcons[ik].Paint = function(se, w, h)
                    se:oPaint(w, h)
                    surface.SetTexture(bubble)
                    surface.DrawTexturedRect(0, 0, w, h)
                    surface.SetDrawColor(color_white)
                    DisableClipping(true)
                    draw.SimpleText(se.Price, "Coolvetica_48", w, h - 24, Color(255, 255, 255, (se:GetWide() / 196) ^ 4 * 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                    DisableClipping(false)
                end

                BestFitModel(self.LocalIcons[ik], 1.9)
            end
        end

        i = i + 1
    end
end

function PANEL:Paint(w, h)
    local mx, my = gui.MousePos()
    local x = ScrW() / 2 - mx
    local y = ScrH() / 2 - my
    draw.SimpleText("$" .. LocalPlayer():GetCredits(), "Coolvetica_48", w / 2 + x + 4, h / 2 + y + 4, Color(200, 255, 75, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function PANEL:Think()
    local x, y = gui.MousePos()
    x = ScrW() / 2 - x
    y = ScrH() / 2 - y

    if (self.Creation < CurTime()) then
        for k, iconpanel in pairs(self.Categories) do
            for i, model in pairs(self.LocalIcons or {}) do
                local fx = model.Parent.FPos[1] + math.cos(model.Parent.Angle + 90) * (i % 3 - 2) * 196 + x + math.cos(model.Parent.Angle) * 196 * math.ceil((i - 1) / 3) + math.sin(RealTime() * 1 + i) * 5
                local fy = model.Parent.FPos[2] + math.sin(model.Parent.Angle + 90) * (i % 3 - 2) * 196 + y + math.sin(model.Parent.Angle) * 196 * math.ceil((i - 1) / 3) + math.cos(RealTime() * 2 + i) * 4
                model.ex = Lerp(FrameTime() * 5, model.ex or 0, (model:IsHovered() and (model.HoveredAt or 0) < CurTime()) and model:GetWide() / 4 or 0)
                model:SetPos(fx - model.ex, fy - model.ex)
            end

            iconpanel:SetPos(iconpanel.FPos[1] + x, iconpanel.FPos[2] + y)
        end
    end
end

derma.DefineControl("dPropSpawner", "Prop spawner", PANEL, "DFrame")

concommand.Add("trn_openbuildmenu", function()
    if (SP) then
        SP:Remove()
    end

    SP = vgui.Create("dPropSpawner")
end)
