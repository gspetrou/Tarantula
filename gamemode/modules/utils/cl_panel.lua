function BestFitModel(panel, zoom)
    local mn, mx = panel.Entity:GetRenderBounds()
    local size = 0
    size = math.max(size, math.abs(mn.x) + math.abs(mx.x))
    size = math.max(size, math.abs(mn.y) + math.abs(mx.y))
    size = math.max(size, math.abs(mn.z) + math.abs(mx.z))
    local diagonal = math.sqrt(size * size * 3) -- Pythagorean theorem, get diagonal distance in box
    local itemViewDir = Vector(1, 1, 1)
    local itemViewZoom = 1 * (zoom or 1)
    panel:SetFOV(45)
    panel:SetCamPos(itemViewDir:GetNormalized() * diagonal * itemViewZoom)
    panel:SetLookAt((mn + mx) * 0.75)
    panel:SetAmbientLight(Color(20, 150, 255, 255))
    panel:SetDirectionalLight(BOX_FRONT, Color(255, 150, 100))
end
