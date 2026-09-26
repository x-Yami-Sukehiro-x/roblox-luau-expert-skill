--[[
	Paragraph - a titled block of text: instructions, credits, a status line.

	    local status = Tab:Paragraph({ Title = "Status", Content = "Waiting for players" })
	    status:Set({ Content = "Round 3 of 5" })

	`Content` uses the description line, so it wraps and stays readable on a
	narrow window instead of truncating.
--]]

local Row = require(script.Parent.Row)

local Paragraph = {}

function Paragraph.new(container: any, options: { [string]: any })
	local row = Row.frame(container, {
		Title = options.Title,
		Description = options.Content or options.Description,
	})
	row.description.TextSize = 14

	function row:Set(fields: { Title: string?, Content: string? })
		if fields.Title then
			self:SetTitle(fields.Title)
		end
		if fields.Content then
			self:SetDescription(fields.Content)
		end
	end

	return row
end

return Paragraph
