--------------------------------------
-- StdUi v1.4.0 ported Lib 23.04.2019
--------------------------------------
local MAJOR, MINOR = 'StdUi', 2

-- [[ Modified ]]
if not TMW then return end
local pairs, tostring = pairs, tostring
if not LibStub then 
	TMW:Print("[Error] LibStub is not initializated")
	return 	 
else
	local StdUi = { LibStub:GetLibrary('StdUi', true) }
	if StdUi[2] and StdUi[2] >= MINOR then 		
		TMW:Print("[Error] StdUi already existed")	
		return 	
	end 
end 
-- [[ END ]]

--------------------------------------
-- StdUi.lua 
--------------------------------------
--- @class StdUi
local StdUi = LibStub:NewLibrary(MAJOR, MINOR)

-- [[ Modified ]]
if not StdUi then
	TMW:Print("[Error] LibStub failed to create class StdUi")
	return 
end
-- [[ END ]]

local function init_StdUi() 
	StdUi.moduleVersions = {};
	StdUiInstances = {StdUi};

	function StdUi:NewInstance()
		local instance = CopyTable(self);
		instance:ResetConfig();
		tinsert(StdUiInstances, instance);
		return instance;
	end

	function StdUi:RegisterModule(module, version)
		self.moduleVersions[module] = version;
	end

	function StdUi:UpgradeNeeded(module, version)
		if not self.moduleVersions[module] then
			return true;
		end

		return self.moduleVersions[module] < version;
	end

	function StdUi:RegisterWidget(name, func)
		if not self[name] then
			self[name] = func;
			return true;
		end
		return false;
	end

	function StdUi:InitWidget(widget)
		widget.isWidget = true;

		function widget:GetChildrenWidgets()
			local children = {widget:GetChildren()};
			local result = {};
			for i = 1, #children do
				local child = children[i];
				if child.isWidget then
					tinsert(result, child);
				end
			end

			return result;
		end
	end

	function StdUi:SetObjSize(obj, width, height)
		if width then
			obj:SetWidth(width);
		end

		if height then
			obj:SetHeight(height);
		end
	end

	function StdUi:SetTextColor(fontString, colorType)
		colorType = colorType or 'normal';
		if fontString.SetTextColor then
			local c = self.config.font.color[colorType];
			fontString:SetTextColor(c.r, c.g, c.b, c.a);
		end
	end

	StdUi.SetHighlightBorder = function(self)
		if self.target then
			self = self.target;
		end

		if self.isDisabled then
			return;
		end

		local hc = StdUi.config.highlight.color;
		if not self.origBackdropBorderColor then
			self.origBackdropBorderColor = {self:GetBackdropBorderColor()};
		end
		self:SetBackdropBorderColor(hc.r, hc.g, hc.b, 1);
	end

	StdUi.ResetHighlightBorder = function(self)
		if self.target then
			self = self.target;
		end

		if self.isDisabled then
			return;
		end

		local hc = self.origBackdropBorderColor;
		self:SetBackdropBorderColor(unpack(hc));
	end

	function StdUi:HookHoverBorder(object)
		object:HookScript('OnEnter', self.SetHighlightBorder);
		object:HookScript('OnLeave', self.ResetHighlightBorder);
	end

	function StdUi:ApplyBackdrop(frame, type, border, insets)
		local config = frame.config or self.config;
		local backdrop = {
			bgFile   = config.backdrop.texture,
			edgeFile = config.backdrop.texture,
			edgeSize = 1,
		};
		if insets then
			backdrop.insets = insets;
		end
		frame:SetBackdrop(backdrop);

		type = type or 'button';
		border = border or 'border';

		if config.backdrop[type] then
			frame:SetBackdropColor(
				config.backdrop[type].r,
				config.backdrop[type].g,
				config.backdrop[type].b,
				config.backdrop[type].a
			);
		end

		if config.backdrop[border] then
			frame:SetBackdropBorderColor(
				config.backdrop[border].r,
				config.backdrop[border].g,
				config.backdrop[border].b,
				config.backdrop[border].a
			);
		end
	end

	function StdUi:ClearBackdrop(frame)
		frame:SetBackdrop(nil);
	end

	function StdUi:ApplyDisabledBackdrop(frame, enabled)
		if frame.target then
			frame = frame.target;
		end
		if enabled then
			self:ApplyBackdrop(frame, 'button', 'border');
			self:SetTextColor(frame, 'normal');
			if frame.label then
				self:SetTextColor(frame.label, 'normal');
			end

			if frame.text then
				self:SetTextColor(frame.text, 'normal');
			end
			frame.isDisabled = false;
		else
			self:ApplyBackdrop(frame, 'buttonDisabled', 'borderDisabled');
			self:SetTextColor(frame, 'disabled');
			if frame.label then
				self:SetTextColor(frame.label, 'disabled');
			end

			if frame.text then
				self:SetTextColor(frame.text, 'disabled');
			end
			frame.isDisabled = true;
		end
	end

	function StdUi:HookDisabledBackdrop(frame)
		local this = self;
		hooksecurefunc(frame, 'Disable', function(self)
			this:ApplyDisabledBackdrop(self, false);
		end);

		hooksecurefunc(frame, 'Enable', function(self)
			this:ApplyDisabledBackdrop(self, true);
		end);
	end

	function StdUi:StripTextures(frame)
		for i = 1, frame:GetNumRegions() do
			local region = select(i, frame:GetRegions());

			if region and region:GetObjectType() == 'Texture' then
				region:SetTexture(nil);
			end
		end
	end

	function StdUi:MakeDraggable(frame, handle)
		frame:SetMovable(true);
		frame:EnableMouse(true);
		frame:RegisterForDrag('LeftButton');
		frame:SetScript('OnDragStart', frame.StartMoving);
		frame:SetScript('OnDragStop', frame.StopMovingOrSizing);

		if handle then
			handle:EnableMouse(true);
			handle:SetMovable(true);
			handle:RegisterForDrag('LeftButton');
			handle:SetScript('OnDragStart', function(self)
				frame.StartMoving(frame);
			end);
			handle:SetScript('OnDragStop', function(self)
				frame.StopMovingOrSizing(frame);
			end);
		end
	end
end 

init_StdUi()


--------------------------------------
-- StdUiBuilder.lua
--------------------------------------
local function init_StdUiBuilder()
	local module, version = 'Builder', 3;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	function __genOrderedIndex(t)
		local orderedIndex = {}
		for key in pairs(t) do
			tinsert(orderedIndex, key)
		end
		table.sort(orderedIndex)
		return orderedIndex
	end

	function orderedNext(t, state)
		local key;

		if state == nil then
			-- the first time, generate the index
			t.__orderedIndex = __genOrderedIndex(t)
			key = t.__orderedIndex[1]
		else
			-- fetch the next value
			for i = 1, table.getn(t.__orderedIndex) do
				if t.__orderedIndex[i] == state then
					key = t.__orderedIndex[i + 1]
				end
			end
		end

		if key then
			return key, t[key]
		end

		-- no more value to return, cleanup
		t.__orderedIndex = nil
		return
	end

	function orderedPairs(t)
		return orderedNext, t, nil
	end

	local function setDatabaseValue(db, key, value)
		if key:find('.') then
			local accessor = StdUi.Util.stringSplit('.', key);
			local startPos = db;

			for i, subKey in pairs(accessor) do
				if i == #accessor then
					startPos[subKey] = value;
					return;
				end

				startPos = db[subKey];
			end
		else
			db[key] = value;
		end
	end

	local function getDatabaseValue(db, key)
		if key:find('.') then
			local accessor = StdUi.Util.stringSplit('.', key);
			local startPos = db;

			for i, subKey in pairs(accessor) do
				if i == #accessor then
					return startPos[subKey];
				end

				startPos = db[subKey];
			end
		else
			return db[key];
		end
	end

	---BuildElement
	---@param frame Frame
	---@param row EasyLayoutRow
	---@param info table
	---@param dataKey string
	---@param db table
	function StdUi:BuildElement(frame, row, info, dataKey, db)
		local element;

		local genericChangeEvent = function(el, value)
			setDatabaseValue(el.dbReference, el.dataKey, value);
			if info.onChange then
				info.onChange(el, value);
			end
		end

		local hasLabel = false;
		if info.type == 'checkbox' then
			element = self:Checkbox(frame, info.label);
			element.dbReference = db;
			element.dataKey = dataKey;

			if db then
				element:SetChecked(getDatabaseValue(db, dataKey));
				element.OnValueChanged = genericChangeEvent;
			end
		elseif info.type == 'text' or info.type == 'editBox' then
			element = self:EditBox(frame, nil, 20);
			element.dbReference = db;
			element.dataKey = dataKey;

			if info.label then
				self:AddLabel(frame, element, info.label);
				hasLabel = true;
			end

			if db then
				element:SetValue(getDatabaseValue(db, dataKey));
				element.OnValueChanged = genericChangeEvent;
			end
		elseif info.type == 'sliderWithBox' then
			element = self:SliderWithBox(frame, nil, 32, 0, info.min or 0, info.max or 2);
			element.dbReference = db;
			element.dataKey = dataKey;

			if info.label then
				self:AddLabel(frame, element, info.label);
				hasLabel = true;
			end

			if info.precision then
				element:SetPrecision(info.precision);
			end

			if db then
				element:SetValue(getDatabaseValue(db, dataKey));
				element.OnValueChanged = genericChangeEvent;
			end
		elseif info.type == 'header' then
			element = StdUi:Header(frame, info.label);
		elseif info.type == 'custom' then
			element = info.createFunction(frame, row, info, dataKey, db);
		end

		row:AddElement(element, {column = info.column or 12, margin = {top = (hasLabel and 20 or 0)}});
		--if hasLabel then
		--	row.config.margin.top = 20;
		--end
	end

	---BuildRow
	---@param frame Frame
	---@param info table
	---@param db table
	function StdUi:BuildRow(frame, info, db)
		local row = frame:AddRow();

		for key, element in orderedPairs(info) do
			local dataKey = element.key or key or nil;

			self:BuildElement(frame, row, element, dataKey, db);
		end
	end

	---BuildWindow
	---@param frame Frame
	---@param info table
	function StdUi:BuildWindow(frame, info)
		local db = info.database or nil;

		assert(info.rows, 'Rows are required in order to build table');
		local rows = info.rows;

		self:EasyLayout(frame, info.layoutConfig);

		for i, row in orderedPairs(rows) do
			self:BuildRow(frame, row, db);
		end

		frame:DoLayout();
	end

	StdUi:RegisterModule(module, version);
end 

init_StdUiBuilder()


--------------------------------------
-- StdUiConfig.lua
--------------------------------------
local function init_StdUiConfig()
	local module, version = 'Config', 3;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	StdUi.config = {};

	function StdUi:ResetConfig()
		local font, fontSize = GameFontNormal:GetFont();
		local _, largeFontSize = GameFontNormalLarge:GetFont();

		self.config = {
			font      = {
				family        = font,
				size          = fontSize,
				titleSize     = largeFontSize,
				effect        = 'NONE',
				strata        = 'OVERLAY',
				color         = {
					normal   = { r = 1, g = 1, b = 1, a = 1 },
					disabled = { r = 0.55, g = 0.55, b = 0.55, a = 1 },
					header   = { r = 1, g = 0.9, b = 0, a = 1 },
				}
			},

			backdrop  = {
				texture        = [[Interface\Buttons\WHITE8X8]],
				panel          = { r = 0.0588, g = 0.0588, b = 0, a = 0.8 },
				slider         = { r = 0.15, g = 0.15, b = 0.15, a = 1 },

				button         = { r = 0.20, g = 0.20, b = 0.20, a = 1 },
				buttonDisabled = { r = 0.15, g = 0.15, b = 0.15, a = 1 },

				border         = { r = 0.00, g = 0.00, b = 0.00, a = 1 },
				borderDisabled = { r = 0.40, g = 0.40, b = 0.40, a = 1 }
			},

			progressBar = {
				color = { r = 1, g = 0.9, b = 0, a = 0.5 },
			},

			highlight = {
				color = { r = 1, g = 0.9, b = 0, a = 0.4 },
				blank = { r = 0, g = 0, b = 0, a = 0 }
			},

			dialog    = {
				width  = 400,
				height = 100,
				button = {
					width  = 100,
					height = 20,
					margin = 5
				}
			},

			tooltip   = {
				padding = 10
			}
		};

		if IsAddOnLoaded('ElvUI') then
			local eb = ElvUI[1].media.backdropfadecolor;
			self.config.backdrop.panel = { r = eb[1],g = eb[2],b = eb[3],a = eb[4] };
		end
	end
	StdUi:ResetConfig();

	function StdUi:SetDefaultFont(font, size, effect, strata)
		self.config.font.family = font;
		self.config.font.size = size;
		self.config.font.effect = effect;
		self.config.font.strata = strata;
	end

	StdUi:RegisterModule(module, version);
end 

init_StdUiConfig()


--------------------------------------
-- StdUiGrid.lua
--------------------------------------
local function init_StdUiGrid()
	local module, version = 'Grid', 1;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	--- Creates frame list that reuses frames and is based on array data
	--- @param parent Frame
	--- @param create function
	--- @param update function
	--- @param data table
	--- @param padding number
	--- @param oX number
	--- @param oY number
	function StdUi:ObjectList(parent, itemsTable, create, update, data, padding, oX, oY)
		oX = oX or 1;
		oY = oY or -1;
		padding = padding or 0;

		if not itemsTable then
			itemsTable = {};
		end

		for i = 1, #itemsTable do
			itemsTable[i]:Hide();
		end

		local totalHeight = -oY;

		for i = 1, #data do
			local itemFrame = itemsTable[i];

			if not itemFrame then
				if type(create) == 'string' then
					-- create a widget and anchor it to
					itemsTable[i] = self[create](self, parent);
				else
					itemsTable[i] = create(parent, data[i], i);
				end
				itemFrame = itemsTable[i];
			end

			-- If you create simple widget you need to handle anchoring yourself
			update(parent, itemFrame, data[i], i);
			itemFrame:Show();

			totalHeight = totalHeight + itemFrame:GetHeight();
			if i == 1 then
				-- glue first item to offset
				self:GlueTop(itemFrame, parent, oX, oY, 'LEFT');
			else
				-- glue next items to previous
				self:GlueBelow(itemFrame, itemsTable[i - 1], 0, -padding);
				totalHeight = totalHeight + padding;
			end
		end

		return itemsTable, totalHeight;
	end

	--- Creates frame list that reuses frames and is based on array data
	--- @param parent Frame
	--- @param create function
	--- @param update function
	--- @param data table
	--- @param size number - size of each wi
	--- @param padding number
	--- @param oX number
	--- @param oY number
	function StdUi:ObjectGrid(parent, itemsMatrix, create, update, data, paddingX, paddingY, oX, oY)
		oX = oX or 1;
		oY = oY or -1;
		paddingX = paddingX or 0;
		paddingY = paddingY or 0;

		if not itemsMatrix then
			itemsMatrix = {};
		end

		for y = 1, #itemsMatrix do
			for x = 1, #itemsMatrix[y] do
				itemsMatrix[y][x]:Hide();
			end
		end

		for rowI = 1, #data do
			local row = data[rowI];

			for colI = 1, #row do
				if not itemsMatrix[rowI] then
					-- whole row does not exist yet
					itemsMatrix[rowI] = {};
				end

				local itemFrame = itemsMatrix[rowI][colI];

				if not itemFrame then
					if type(create) == 'string' then
						-- create a widget and set parent it to
						itemFrame = self[create](self, parent);
					else
						itemFrame = create(parent, data[rowI][colI], rowI, colI);
					end
					itemsMatrix[rowI][colI] = itemFrame;
				end

				-- If you create simple widget you need to handle anchoring yourself
				update(parent, itemFrame, data[rowI][colI], rowI, colI);
				itemFrame:Show();

				if rowI == 1 and colI == 1 then
					-- glue first item to offset
					self:GlueTop(itemFrame, parent, oX, oY, 'LEFT');
				else
					if colI == 1 then
						-- glue first item in column to previous row
						self:GlueBelow(itemFrame, itemsMatrix[rowI - 1][colI], 0, -paddingY, 'LEFT');
					else
						-- glue next column to previous column
						self:GlueRight(itemFrame, itemsMatrix[rowI][colI - 1], paddingX, 0);
					end
				end
			end
		end
	end

	StdUi:RegisterModule(module, version);
end 

init_StdUiGrid()


--------------------------------------
-- StdUiLayout.lua
--------------------------------------
local function init_StdUiLayout()
	local module, version = 'Layout', 2;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	local defaultLayoutConfig = {
		gutter = 10,
		columns = 12,
		padding = {
			top = 0,
			right = 10,
			left = 10
		}
	};

	local defaultRowConfig = {
		margin = {
			top = 0,
			right = 0,
			bottom = 15,
			left = 0
		}
	};

	local defaultElementConfig = {
		margin = {
			top = 0,
			right = 0,
			bottom = 0,
			left = 0
		}
	};


	---EasyLayoutRow
	---@param parent Frame
	---@param config table
	function StdUi:EasyLayoutRow(parent, config)
		---@class EasyLayoutRow
		local row = {
			parent = parent,
			config = self.Util.tableMerge(defaultRowConfig, config or {}),
			elements = {}
		};

		function row:AddElement(frame, config)
			if not frame.layoutConfig then
				frame.layoutConfig = StdUi.Util.tableMerge(defaultElementConfig , config or {});
			elseif config then
				frame.layoutConfig = StdUi.Util.tableMerge(frame.layoutConfig , config or {});
			end

			tinsert(row.elements, frame);
		end

		function row:AddElements(...)
			local r = {...};
			local cfg = tremove(r, #r);

			if cfg.column == 'even' then
				cfg.column = math.floor(self.parent.layout.columns / #r);
			end

			for i = 1, #r do
				self:AddElement(r[i], StdUi.Util.tableMerge(defaultElementConfig, cfg));
			end
		end

		function row:DrawRow(parentWidth, yOffset)
			yOffset = yOffset or 0;
			local l = self.parent.layout;
			local g = l.gutter;

			local rowMargin = self.config.margin;
			local totalHeight = 0;
			local columnsTaken = 0;
			local x = g + l.padding.left + rowMargin.left;

			-- if row has margins, cut down available width
			parentWidth = parentWidth - rowMargin.left - rowMargin.right;

			for i = 1, #self.elements do
				local frame = self.elements[i];

				frame:ClearAllPoints();

				local lc = frame.layoutConfig;
				local m = lc.margin;

				local col = lc.column or l.columns;
				local w = (parentWidth / (l.columns / col)) - 2 * g;

				frame:SetWidth(w);

				if columnsTaken + col > self.parent.layout.columns then
					print('Element will not fit row capacity: ' .. l.columns);
					return totalHeight;
				end

				-- move it down by rowMargin and element margin
				frame:SetPoint('TOPLEFT', self.parent, 'TOPLEFT', x, yOffset - m.top - rowMargin.top);

				--each element takes 1 gutter plus column * colWidth, while gutter is inclusive
				x = x + w + 2 * g; -- double the gutter because width subtracts gutter

				totalHeight = math.max(totalHeight, frame:GetHeight() + m.bottom + m.top + rowMargin.top + rowMargin.bottom);
				columnsTaken = columnsTaken + col;
			end

			return totalHeight;
		end

		function row:GetColumnsTaken()
			local columnsTaken = 0;
			local l = self.parent.layout;

			for i = 1, #self.elements do
				local lc = self.elements[i].layoutConfig;
				local col = lc.column or l.columns;
				columnsTaken = columnsTaken + col;
			end

			return columnsTaken;
		end

		return row;
	end

	function StdUi:EasyLayout(parent, config)
		local stdUi = self;

		parent.layout = self.Util.tableMerge(defaultLayoutConfig, config or {});

		---@return EasyLayoutRow
		function parent:AddRow(config)
			if not self.rows then self.rows = {}; end

			local row = stdUi:EasyLayoutRow(self, config);
			tinsert(self.rows, row);

			return row;
		end

		function parent:DoLayout()
			local l = self.layout;
			local width = self:GetWidth() - l.padding.left - l.padding.right;

			local y = -l.padding.top;
			for i = 1, #self.rows do
				local r = self.rows[i];
				y = y - r:DrawRow(width, y);
			end
		end
	end

	StdUi:RegisterModule(module, version);
end

init_StdUiLayout()


--------------------------------------
-- StdUiPosition.lua
--------------------------------------
local function init_StdUiPosition()
	local module, version = 'Position', 1;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	-- Points
	local Top = 'TOP';
	local Bottom = 'BOTTOM';
	local Left = 'LEFT';
	local Right = 'RIGHT';

	local TopLeft = 'TOPLEFT';
	local TopRight = 'TOPRIGHT';
	local BottomLeft = 'BOTTOMLEFT';
	local BottomRight = 'BOTTOMRIGHT';

	--- Glues object below referenced object
	function StdUi:GlueBelow(object, referencedObject, x, y, align)
		if align == Left then
			object:SetPoint(TopLeft, referencedObject, BottomLeft, x, y);
		elseif align == Right then
			object:SetPoint(TopRight, referencedObject, BottomRight, x, y);
		else
			object:SetPoint(Top, referencedObject, Bottom, x, y);
		end
	end

	--- Glues object above referenced object
	function StdUi:GlueAbove(object, referencedObject, x, y, align)
		if align == Left then
			object:SetPoint(BottomLeft, referencedObject, TopLeft, x, y);
		elseif align == Right then
			object:SetPoint(BottomRight, referencedObject, TopRight, x, y);
		else
			object:SetPoint(Bottom, referencedObject, Top, x, y);
		end
	end

	function StdUi:GlueTop(object, referencedObject, x, y, align)
		if align == Left then
			object:SetPoint(TopLeft, referencedObject, TopLeft, x, y);
		elseif align == Right then
			object:SetPoint(TopRight, referencedObject, TopRight, x, y);
		else
			object:SetPoint(Top, referencedObject, Top, x, y);
		end
	end

	function StdUi:GlueBottom(object, referencedObject, x, y, align)
		if align == Left then
			object:SetPoint(BottomLeft, referencedObject, BottomLeft, x, y);
		elseif align == Right then
			object:SetPoint(BottomRight, referencedObject, BottomRight, x, y);
		else
			object:SetPoint(Bottom, referencedObject, Bottom, x, y);
		end
	end

	function StdUi:GlueRight(object, referencedObject, x, y, inside)
		if inside then
			object:SetPoint(Right, referencedObject, Right, x, y);
		else
			object:SetPoint(Left, referencedObject, Right, x, y);
		end
	end

	function StdUi:GlueLeft(object, referencedObject, x, y, inside)
		if inside then
			object:SetPoint(Left, referencedObject, Left, x, y);
		else
			object:SetPoint(Right, referencedObject, Left, x, y);
		end
	end

	function StdUi:GlueAfter(object, referencedObject, topX, topY, bottomX, bottomY)
		if topX and topY then
			object:SetPoint(TopLeft, referencedObject, TopRight, topX, topY);
		end
		if bottomX and bottomY then
			object:SetPoint(BottomLeft, referencedObject, BottomRight, bottomX, bottomY);
		end
	end

	function StdUi:GlueBefore(object, referencedObject, topX, topY, bottomX, bottomY)
		if topX and topY then
			object:SetPoint(TopRight, referencedObject, TopLeft, topX, topY);
		end
		if bottomX and bottomY then
			object:SetPoint(BottomRight, referencedObject, BottomLeft, bottomX, bottomY);
		end
	end

	-- More advanced positioning functions
	function StdUi:GlueAcross(object, referencedObject, topLeftX, topLeftY, bottomRightX, bottomRightY)
		object:SetPoint(TopLeft, referencedObject, TopLeft, topLeftX, topLeftY);
		object:SetPoint(BottomRight, referencedObject, BottomRight, bottomRightX, bottomRightY);
	end

	-- Glues object to opposite side of anchor
	function StdUi:GlueOpposite(object, referencedObject, x, y, anchor)
		if anchor == 'TOP' then 			object:SetPoint('BOTTOM', referencedObject, anchor, x, y);
		elseif anchor == 'BOTTOM' then		object:SetPoint('TOP', referencedObject, anchor, x, y);
		elseif anchor == 'LEFT' then		object:SetPoint('RIGHT', referencedObject, anchor, x, y);
		elseif anchor == 'RIGHT' then		object:SetPoint('LEFT', referencedObject, anchor, x, y);
		elseif anchor == 'TOPLEFT' then		object:SetPoint('BOTTOMRIGHT', referencedObject, anchor, x, y);
		elseif anchor == 'TOPRIGHT' then	object:SetPoint('BOTTOMLEFT', referencedObject, anchor, x, y);
		elseif anchor == 'BOTTOMLEFT' then	object:SetPoint('TOPRIGHT', referencedObject, anchor, x, y);
		elseif anchor == 'BOTTOMRIGHT' then	object:SetPoint('TOPLEFT', referencedObject, anchor, x, y);
		else								object:SetPoint('CENTER', referencedObject, anchor, x, y);
		end
	end

	StdUi:RegisterModule(module, version);
end 

init_StdUiPosition()


--------------------------------------
-- StdUiUtil.lua
--------------------------------------
local function init_StdUiUtil()
	local module, version = 'Util', 4;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	--- @param frame Frame
	function StdUi:MarkAsValid(frame, valid)
		if not valid then
			frame:SetBackdropBorderColor(1, 0, 0, 1);
		else
			frame:SetBackdropBorderColor(
				self.config.backdrop.border.r,
				self.config.backdrop.border.g,
				self.config.backdrop.border.b,
				self.config.backdrop.border.a
			);
		end
	end

	StdUi.Util = {};

	--- @param self EditBox
	StdUi.Util.editBoxValidator = function(self)
		self.value = self:GetText();

		StdUi:MarkAsValid(self, true);
		return true;
	end

	--- @param self EditBox
	StdUi.Util.moneyBoxValidator = function(self)
		local text = self:GetText();
		text = text:trim();
		local total, gold, silver, copper, isValid = StdUi.Util.parseMoney(text);

		if not isValid or total == 0 then
			StdUi:MarkAsValid(self, false);
			return false;
		end

		self:SetText(StdUi.Util.formatMoney(total));
		self.value = total;

		StdUi:MarkAsValid(self, true);
		return true;
	end

	--- @param self EditBox
	StdUi.Util.numericBoxValidator = function(self)
		local text = self:GetText();
		text = text:trim();

		local value = tonumber(text);

		if value == nil then
			StdUi:MarkAsValid(self, false);
			return false;
		end

		if self.maxValue and self.maxValue < value then
			StdUi:MarkAsValid(self, false);
			return false;
		end

		if self.minValue and self.minValue > value then
			StdUi:MarkAsValid(self, false);
			return false;
		end

		self.value = value;

		StdUi:MarkAsValid(self, true);

		return true;
	end

	StdUi.Util.spellValidator = function(self)
		local text = self:GetText();
		text = text:trim();
		local name, _, icon, _, _, _, spellId = GetSpellInfo(text);

		if not name then
			StdUi:MarkAsValid(self, false);
			return false;
		end

		self:SetText(name);
		self.value = spellId;
		self.icon:SetTexture(icon);

		StdUi:MarkAsValid(self, true);
		return true;
	end

	StdUi.Util.parseMoney = function(text)
		text = StdUi.Util.stripColors(text);
		local total = 0;
		local cFound, _, copper = string.find(text, '(%d+)c$');
		if cFound then
			text = string.gsub(text, '(%d+)c$', '');
			text = text:trim();
			total = tonumber(copper);
		end

		local sFound, _, silver = string.find(text, '(%d+)s$');
		if sFound then
			text = string.gsub(text, '(%d+)s$', '');
			text = text:trim();
			total = total + tonumber(silver) * 100;
		end

		local gFound, _, gold = string.find(text, '(%d+)g$');
		if gFound then
			text = string.gsub(text, '(%d+)g$', '');
			text = text:trim();
			total = total + tonumber(gold) * 100 * 100;
		end

		local left = tonumber(text:len());
		local isValid = (text:len() == 0 and total > 0);

		return total, gold, silver, copper, isValid;
	end

	StdUi.Util.formatMoney = function(money)
		if type(money) ~= 'number' then
			return money;
		end

		money = tonumber(money);
		local goldColor = '|cfffff209';
		local silverColor = '|cff7b7b7a';
		local copperColor = '|cffac7248';

		local gold = floor(money / COPPER_PER_GOLD);
		local silver = floor((money - (gold * COPPER_PER_GOLD)) / COPPER_PER_SILVER);
		local copper = floor(money % COPPER_PER_SILVER);

		local output = '';

		if gold > 0 then
			output = format('%s%i%s ', goldColor, gold, '|rg')
		end

		if gold > 0 or silver > 0 then
			output = format('%s%s%02i%s ', output, silverColor, silver, '|rs')
		end

		output = format('%s%s%02i%s ', output, copperColor, copper, '|rc')

		return output:trim();
	end

	StdUi.Util.stripColors = function(text)
		text = string.gsub(text, '|c%x%x%x%x%x%x%x%x', '');
		text = string.gsub(text, '|r', '');
		return text;
	end

	StdUi.Util.WrapTextInColor = function(text, r, g, b, a)
		local hex = string.format(
			'%02x%02x%02x%02x',
			Clamp(a * 255, 0, 255),
			Clamp(r * 255, 0, 255),
			Clamp(g * 255, 0, 255),
			Clamp(b * 255, 0, 255)
		);

		return WrapTextInColorCode(text, hex);
	end

	StdUi.Util.tableCount = function(tab)
		local n = #tab;

		if (n == 0) then
			for _ in pairs(tab) do
				n = n + 1;
			end
		end

		return n;
	end

	StdUi.Util.tableMerge = function(default, new)
		local result = {};
		for k, v in pairs(default) do
			if type(v) == 'table' then
				if new[k] then
					result[k] = StdUi.Util.tableMerge(v, new[k]);
				else
					result[k] = v;
				end
			else
				result[k] = new[k] or default[k];
			end
		end

		for k, v in pairs(new) do
			if not result[k] then
				result[k] = v;
			end
		end

		return result;
	end

	StdUi.Util.stringSplit = function(separator, input, limit)
		return { strsplit(separator, input, limit) };
	end

	StdUi:RegisterModule(module, version);
end 

init_StdUiUtil()


--------------------------------------
-- Widgets: Basic.lua
--------------------------------------
local function init_Basic()
	local module, version = 'Basic', 2;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	function StdUi:Frame(parent, width, height, inherits)
		local frame = CreateFrame('Frame', nil, parent, inherits);
		self:InitWidget(frame);
		self:SetObjSize(frame, width, height);

		return frame;
	end

	function StdUi:Panel(parent, width, height, inherits)
		local frame = self:Frame(parent, width, height, inherits);
		self:ApplyBackdrop(frame, 'panel');

		return frame;
	end

	function StdUi:PanelWithLabel(parent, width, height, inherits, text)
		local frame = self:Panel(parent, width, height, inherits);

		frame.label = self:Header(frame, text);
		frame.label:SetAllPoints();
		frame.label:SetJustifyH('MIDDLE');

		return frame;
	end

	function StdUi:PanelWithTitle(parent, width, height, text)
		local frame = self:Panel(parent, width, height);

		frame.titlePanel = self:PanelWithLabel(frame, 100, 20, nil, text);
		frame.titlePanel:SetPoint('TOP', 0, -10);
		frame.titlePanel:SetPoint('LEFT', 30, 0);
		frame.titlePanel:SetPoint('RIGHT', -30, 0);
		frame.titlePanel:SetBackdrop(nil);

		return frame;
	end

	--- @return Texture
	function StdUi:Texture(parent, width, height, texture)
		local tex = parent:CreateTexture(nil, 'ARTWORK');

		self:SetObjSize(tex, width, height);
		if texture then
			tex:SetTexture(texture);
		end

		return tex;
	end

	--- @return Texture
	function StdUi:ArrowTexture(parent, direction)
		local texture = self:Texture(parent, 16, 8, [[Interface\Buttons\Arrow-Up-Down]]);

		if direction == 'UP' then
			texture:SetTexCoord(0, 1, 0.5, 1);
		else
			texture:SetTexCoord(0, 1, 1, 0.5);
		end

		return texture;
	end

	StdUi:RegisterModule(module, version);
end 

init_Basic()


--------------------------------------
-- Widgets: Button.lua
--------------------------------------
local function init_Button()
	local module, version = 'Button', 3;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	local SquareButtonCoords = {
		UP = {     0.45312500,    0.64062500,     0.01562500,     0.20312500};
		DOWN = {   0.45312500,    0.64062500,     0.20312500,     0.01562500};
		LEFT = {   0.23437500,    0.42187500,     0.01562500,     0.20312500};
		RIGHT = {  0.42187500,    0.23437500,     0.01562500,     0.20312500};
		DELETE = { 0.01562500,    0.20312500,     0.01562500,     0.20312500};
	};

	function StdUi:SquareButton(parent, width, height, icon)
		local this = self;
		local button = CreateFrame('Button', nil, parent);
		self:InitWidget(button);
		self:SetObjSize(button, width, height);

		self:ApplyBackdrop(button);
		self:HookDisabledBackdrop(button);
		self:HookHoverBorder(button);

		function button:SetIconDisabled(texture, width, height)
			button.iconDisabled = this:Texture(button, width, height, texture);
			button.iconDisabled:SetDesaturated(true);
			button.iconDisabled:SetPoint('CENTER', 0, 0);

			button:SetDisabledTexture(button.iconDisabled);
		end

		function button:SetIcon(texture, width, height, alsoDisabled)
			button.icon = this:Texture(button, width, height, texture);
			button.icon:SetPoint('CENTER', 0, 0);

			button:SetNormalTexture(button.icon);

			if alsoDisabled then
				button:SetIconDisabled(texture, width, height);
			end
		end


		local coords = SquareButtonCoords[icon];
		if coords then
			button:SetIcon([[Interface\Buttons\SquareButtonTextures]], 16, 16, true);
			button.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
			button.iconDisabled:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
		end

		return button;
	end

	function StdUi:ButtonLabel(parent, text)
		local label = self:Label(parent, text);
		label:SetJustifyH('CENTER');
		self:GlueAcross(label, parent, 2, -2, -2, 2);
		parent:SetFontString(label);

		return label;
	end

	function StdUi:HighlightButtonTexture(button)
		local hTex = self:Texture(button, nil, nil, nil);
		hTex:SetColorTexture(
			self.config.highlight.color.r,
			self.config.highlight.color.g,
			self.config.highlight.color.b,
			self.config.highlight.color.a
		);
		hTex:SetAllPoints();

		return hTex;
	end

	--- Creates a button with only a highlight
	--- @return Button
	function StdUi:HighlightButton(parent, width, height, text, inherit)
		local button = CreateFrame('Button', nil, parent, inherit);
		self:InitWidget(button);
		self:SetObjSize(button, width, height);
		button.text = self:ButtonLabel(button, text);

		local hTex = self:HighlightButtonTexture(button);
		hTex:SetBlendMode('ADD');

		button:SetHighlightTexture(hTex);
		button.highlightTexture = hTex;

		return button;
	end

	--- @return Button
	function StdUi:Button(parent, width, height, text, inherit)
		local button = self:HighlightButton(parent, width, height, text, inherit)
		button:SetHighlightTexture(nil);

		self:ApplyBackdrop(button);
		self:HookDisabledBackdrop(button);
		self:HookHoverBorder(button);

		return button;
	end

	function StdUi:ButtonAutoWidth(button, padding)
		padding = padding or 5;
		button:SetWidth(button.text:GetStringWidth() + padding * 2);
	end

	StdUi:RegisterModule(module, version);
end 

init_Button()


--------------------------------------
-- Widgets: Checkbox.lua
--------------------------------------
local function init_Checkbox()
	local module, version = 'Checkbox', 2;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	---@return CheckButton
	function StdUi:Checkbox(parent, text, width, height)
		local checkbox = CreateFrame('Button', nil, parent);
		checkbox:EnableMouse(true);
		self:SetObjSize(checkbox, width, height or 20);
		self:InitWidget(checkbox);

		checkbox.target = self:Panel(checkbox, 16, 16);
		checkbox.target:SetPoint('LEFT', 0, 0);

		checkbox.value = true;
		checkbox.isChecked = false;

		checkbox.text = self:Label(checkbox, text);
		checkbox.text:SetPoint('LEFT', checkbox.target, 'RIGHT', 5, 0);
		checkbox.text:SetPoint('RIGHT', checkbox, 'RIGHT', -5, 0);
		checkbox.target.text = checkbox.text; -- reference for disabled

		checkbox.checkedTexture = self:Texture(checkbox.target, nil, nil, [[Interface\Buttons\UI-CheckBox-Check]]);
		checkbox.checkedTexture:SetAllPoints();
		checkbox.checkedTexture:Hide();

		checkbox.disabledCheckedTexture = self:Texture(checkbox.target, nil, nil,
			[[Interface\Buttons\UI-CheckBox-Check-Disabled]]);
		checkbox.disabledCheckedTexture:SetAllPoints();
		checkbox.disabledCheckedTexture:Hide();

		function checkbox:GetChecked()
			return self.isChecked;
		end

		function checkbox:SetChecked(flag)
			self.isChecked = flag;

			if self.OnValueChanged then
				self:OnValueChanged(flag, self.value);
			end

			if not flag then
				self.checkedTexture:Hide();
				self.disabledCheckedTexture:Hide();
				return;
			end

			if self.isDisabled then
				self.checkedTexture:Hide();
				self.disabledCheckedTexture:Show();
			else
				self.checkedTexture:Show();
				self.disabledCheckedTexture:Hide();
			end
		end

		function checkbox:SetText(text)
			self.text:SetText(text);
		end

		function checkbox:SetValue(value)
			self.value = value;
		end

		function checkbox:GetValue()
			if self:GetChecked() then
				return self.value;
			else
				return nil;
			end
		end

		function checkbox:Disable()
			self.isDisabled = true;
			self:SetChecked(self.isChecked);
		end

		function checkbox:Enable()
			self.isDisabled = false;
			self:SetChecked(self.isChecked);
		end

		function checkbox:AutoWidth()
			self:SetWidth(self.target:GetWidth() + 15 + self.text:GetWidth());
		end

		self:ApplyBackdrop(checkbox.target);
		self:HookDisabledBackdrop(checkbox);
		self:HookHoverBorder(checkbox);

		if width == nil then
			checkbox:AutoWidth();
		end

		checkbox:SetScript('OnClick', function(frame)
			if not frame.isDisabled then
				frame:SetChecked(not frame:GetChecked());
			end
		end);

		return checkbox;
	end

	---@return CheckButton
	function StdUi:Radio(parent, text, groupName, width, height)
		local radio = self:Checkbox(parent, text, width, height);

		radio.checkedTexture = self:Texture(radio.target, nil, nil, [[Interface\Buttons\UI-RadioButton]]);
		radio.checkedTexture:SetAllPoints(radio.target);
		radio.checkedTexture:Hide();
		radio.checkedTexture:SetTexCoord(0.25, 0.5, 0, 1);

		radio.disabledCheckedTexture = self:Texture(radio.target, nil, nil,
			[[Interface\Buttons\UI-RadioButton]]);
		radio.disabledCheckedTexture:SetAllPoints(radio.target);
		radio.disabledCheckedTexture:Hide();
		radio.disabledCheckedTexture:SetTexCoord(0.75, 1, 0, 1);

		radio:SetScript('OnClick', function(frame)
			if not frame.isDisabled then
				frame:SetChecked(true);
			end
		end);

		if groupName then
			self:AddToRadioGroup(groupName, radio);
		end

		return radio;
	end

	StdUi.radioGroups = {};

	---@return CheckButton[]
	function StdUi:RadioGroup(groupName)
		if not self.radioGroups[groupName] then
			self.radioGroups[groupName] = {};
		end

		return self.radioGroups[groupName];
	end

	function StdUi:GetRadioGroupValue(groupName)
		local group = self:RadioGroup(groupName);

		for i = 1, #group do
			local radio = group[i];
			if radio:GetChecked() then
				return radio:GetValue();
			end
		end

		return nil;
	end

	function StdUi:SetRadioGroupValue(groupName, value)
		local group = self:RadioGroup(groupName);

		for i = 1, #group do
			local radio = group[i];
			radio:SetChecked(radio.value == value)
		end

		return nil;
	end

	function StdUi:OnRadioGroupValueChanged(groupName, callback)
		local group = self:RadioGroup(groupName);

		local function changed(radio, flag, value)
			radio.notified = true;

			-- We must get all notifications from group
			for i = 1, #group do
				if not group[i].notified then
					return;
				end
			end

			callback(self:GetRadioGroupValue(groupName), groupName);

			for i = 1, #group do
				group[i].notified = false;
			end
		end

		for i = 1, #group do
			local radio = group[i];
			radio.OnValueChanged = changed;
		end

		return nil;
	end

	function StdUi:AddToRadioGroup(groupName, frame)
		local group = self:RadioGroup(groupName);
		tinsert(group, frame);
		frame.radioGroup = group;

		frame:HookScript('OnClick', function(radio)
			for i = 1, #radio.radioGroup do
				local otherRadio = radio.radioGroup[i];
				if otherRadio ~= radio then
					otherRadio:SetChecked(false);
				end
			end
		end);
	end

	StdUi:RegisterModule(module, version);
end 

init_Checkbox()


--------------------------------------
-- Widgets: ColorPicker.lua
--------------------------------------
local function init_ColorPicker()
	local module, version = 'ColorPicker', 1;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	--- alphaSliderTexture = [[Interface\AddOns\YourAddon\Libs\StdUi\media\Checkers.tga]]
	function StdUi:ColorPicker(parent, alphaSliderTexture)
		local wheelWidth = 128;
		local thumbWidth = 10;
		local barWidth = 16;

		local cpf = CreateFrame('ColorSelect', nil, parent);
		--self:MakeDraggable(cpf);
		cpf:SetPoint('CENTER');
		self:ApplyBackdrop(cpf, 'panel');
		self:SetObjSize(cpf, 340, 200);

		-- Create colorpicker wheel.
		cpf.wheelTexture = self:Texture(cpf, wheelWidth, wheelWidth);
		self:GlueTop(cpf.wheelTexture, cpf, 10, -10, 'LEFT');

		cpf.wheelThumbTexture = self:Texture(cpf, thumbWidth, thumbWidth, [[Interface\Buttons\UI-ColorPicker-Buttons]]);
		cpf.wheelThumbTexture:SetTexCoord(0, 0.15625, 0, 0.625);

		-- Create the colorpicker slider.
		cpf.valueTexture = self:Texture(cpf, barWidth, wheelWidth);
		self:GlueRight(cpf.valueTexture, cpf.wheelTexture, 10, 0);

		cpf.valueThumbTexture = self:Texture(cpf, barWidth, thumbWidth, [[Interface\Buttons\UI-ColorPicker-Buttons]]);
		cpf.valueThumbTexture:SetTexCoord(0.25, 1, 0.875, 0);

		cpf:SetColorWheelTexture(cpf.wheelTexture);
		cpf:SetColorWheelThumbTexture(cpf.wheelThumbTexture);
		cpf:SetColorValueTexture(cpf.valueTexture);
		cpf:SetColorValueThumbTexture(cpf.valueThumbTexture);

		cpf.alphaSlider = CreateFrame('Slider', nil, cpf);
		cpf.alphaSlider:SetOrientation('VERTICAL');
		cpf.alphaSlider:SetMinMaxValues(0, 100);
		cpf.alphaSlider:SetValue(0);
		self:SetObjSize(cpf.alphaSlider, barWidth, wheelWidth + thumbWidth); -- hack
		self:GlueRight(cpf.alphaSlider, cpf.valueTexture, 10, 0);

		cpf.alphaTexture = self:Texture(cpf.alphaSlider, nil, nil, alphaSliderTexture);
		self:GlueAcross(cpf.alphaTexture, cpf.alphaSlider, 0, -thumbWidth / 2, 0, thumbWidth / 2); -- hack
		--cpf.alphaTexture:SetColorTexture(1, 1, 1, 1);
		--cpf.alphaTexture:SetGradientAlpha('VERTICAL', 0, 0, 0, 1, 1, 1, 1, 1);

		cpf.alphaThumbTexture = self:Texture(cpf.alphaSlider, barWidth, thumbWidth,
				[[Interface\Buttons\UI-ColorPicker-Buttons]]);
		cpf.alphaThumbTexture:SetTexCoord(0.275, 1, 0.875, 0);
		cpf.alphaThumbTexture:SetDrawLayer('ARTWORK', 2);
		cpf.alphaSlider:SetThumbTexture(cpf.alphaThumbTexture);


		cpf.newTexture = self:Texture(cpf, 32, 32, [[Interface\Buttons\WHITE8X8]]);
		cpf.oldTexture = self:Texture(cpf, 32, 32, [[Interface\Buttons\WHITE8X8]]);
		cpf.newTexture:SetDrawLayer('ARTWORK', 5);
		cpf.oldTexture:SetDrawLayer('ARTWORK', 4);

		self:GlueTop(cpf.newTexture, cpf, -30, -30, 'RIGHT');
		self:GlueBelow(cpf.oldTexture, cpf.newTexture, 20, 45);

		----------------------------------------------------
		--- Buttons
		----------------------------------------------------

		cpf.rEdit = self:NumericBox(cpf, 60, 20);
		cpf.gEdit = self:NumericBox(cpf, 60, 20);
		cpf.bEdit = self:NumericBox(cpf, 60, 20);
		cpf.aEdit = self:NumericBox(cpf, 60, 20);

		cpf.rEdit:SetMinMaxValue(0, 255);
		cpf.gEdit:SetMinMaxValue(0, 255);
		cpf.bEdit:SetMinMaxValue(0, 255);
		cpf.aEdit:SetMinMaxValue(0, 100);

		self:AddLabel(cpf, cpf.rEdit, 'R', 'LEFT');
		self:AddLabel(cpf, cpf.gEdit, 'G', 'LEFT');
		self:AddLabel(cpf, cpf.bEdit, 'B', 'LEFT');
		self:AddLabel(cpf, cpf.aEdit, 'A', 'LEFT');

		self:GlueAfter(cpf.rEdit, cpf.alphaSlider, 20, -thumbWidth / 2);
		self:GlueBelow(cpf.gEdit, cpf.rEdit, 0, -10);
		self:GlueBelow(cpf.bEdit, cpf.gEdit, 0, -10);
		self:GlueBelow(cpf.aEdit, cpf.bEdit, 0, -10);

		cpf.okButton = StdUi:Button(cpf, 100, 20, OKAY);
		cpf.cancelButton = StdUi:Button(cpf, 100, 20, CANCEL);
		self:GlueBottom(cpf.okButton, cpf, 40, 20, 'LEFT');
		self:GlueBottom(cpf.cancelButton, cpf, -40, 20, 'RIGHT');

		----------------------------------------------------
		--- Methods
		----------------------------------------------------

		function cpf:SetColorRGBA(r, g, b, a)
			self:SetColorAlpha(a);
			self:SetColorRGB(r, g, b);

			self.newTexture:SetVertexColor(r, g, b, a);
		end

		function cpf:GetColorRGBA()
			local r, g, b = self:GetColorRGB();
			return r, g, b, self:GetColorAlpha();
		end

		function cpf:SetColorAlpha(a, fromSlider)
			a = Clamp(a, 0, 1);

			if not fromSlider then
				self.alphaSlider:SetValue(100 - a * 100);
			end

			self.aEdit:SetValue(Round(a * 100));
			self.aEdit:Validate();
			self:SetColorRGB(self:GetColorRGB());
		end

		function cpf:GetColorAlpha()
			local a = Clamp(tonumber(self.aEdit:GetValue()) or 100, 0, 100);
			return a / 100;
		end

		----------------------------------------------------
		--- Events
		----------------------------------------------------

		cpf.alphaSlider:SetScript('OnValueChanged', function(slider)
			cpf:SetColorAlpha((100 - slider:GetValue()) / 100, true);
		end);

		cpf:SetScript('OnColorSelect', function(self)
			-- Ensure custom fields are updated.
			local r, g, b, a = self:GetColorRGBA();

			if not self.skipTextUpdate then
				self.rEdit:SetValue(r * 255);
				self.gEdit:SetValue(g * 255);
				self.bEdit:SetValue(b * 255);
				self.aEdit:SetValue(100 * a);

				self.rEdit:Validate();
				self.gEdit:Validate();
				self.bEdit:Validate();
				self.aEdit:Validate();
			end

			self.newTexture:SetVertexColor(r, g, b, a);
			self.alphaTexture:SetGradientAlpha('VERTICAL', 1, 1, 1, 0, r, g, b, 1);
		end);

		local function OnValueChanged()
			local r = tonumber(cpf.rEdit:GetValue() or 255) / 255;
			local g = tonumber(cpf.gEdit:GetValue() or 255) / 255;
			local b = tonumber(cpf.bEdit:GetValue() or 255) / 255;
			local a = tonumber(cpf.aEdit:GetValue() or 100) / 100;

			cpf.skipTextUpdate = true;
			cpf:SetColorRGB(r, g, b);
			cpf.alphaSlider:SetValue(100 - a * 100);
			cpf.skipTextUpdate = false;
		end


		cpf.rEdit.OnValueChanged = OnValueChanged;
		cpf.gEdit.OnValueChanged = OnValueChanged;
		cpf.bEdit.OnValueChanged = OnValueChanged;
		cpf.aEdit.OnValueChanged = OnValueChanged;

		return cpf;
	end

	-- placeholder
	StdUi.colorPickerFrame = nil;
	function StdUi:ColorPickerFrame(r, g, b, a, okCallback, cancelCallback, alphaSliderTexture)
		local colorPickerFrame = self.colorPickerFrame;
		if not colorPickerFrame then
			colorPickerFrame = self:ColorPicker(UIParent, alphaSliderTexture);
			colorPickerFrame:SetFrameStrata('FULLSCREEN_DIALOG');
			self.colorPickerFrame = colorPickerFrame;
		end

		colorPickerFrame.okButton:SetScript('OnClick', function (self)
			if okCallback then
				okCallback(colorPickerFrame);
			end
			colorPickerFrame:Hide();
		end);

		colorPickerFrame.cancelButton:SetScript('OnClick', function (self)
			if cancelCallback then
				cancelCallback(colorPickerFrame);
			end
			colorPickerFrame:Hide();
		end);

		colorPickerFrame:SetColorRGBA(r or 1, g or 1, b or 1, a or 1);
		colorPickerFrame.oldTexture:SetVertexColor(r or 1, g or 1, b or 1, a or 1);

		colorPickerFrame:ClearAllPoints();
		colorPickerFrame:SetPoint('CENTER');
		colorPickerFrame:Show();
	end

	function StdUi:ColorInput(parent, label, width, height, r, g, b, a)
		local this = self;

		local button = CreateFrame('Button', nil, parent);
		button:EnableMouse(true);
		self:SetObjSize(button, width, height or 20);
		self:InitWidget(button);

		button.target = self:Panel(button, 16, 16);
		button.target:SetPoint('LEFT', 0, 0);

		button.text = self:Label(button, label);
		button.text:SetPoint('LEFT', button.target, 'RIGHT', 5, 0);
		button.text:SetPoint('RIGHT', button, 'RIGHT', -5, 0);

		button.color = {};

		function button:SetColor(r, g, b, a)
			if type(r) == 'table' then
				self.color.r = r.r;
				self.color.g = r.g;
				self.color.b = r.b;
				self.color.a = r.a;
			elseif type(r) == 'string' then

			else
				self.color = {
					r = r, g = g, b = b, a = a,
				};
			end

			self.target:SetBackdropColor(r, g, b, a);
			if self.OnValueChanged then
				self:OnValueChanged(r, g, b, a);
			end
		end

		function button:GetColor(type)
			if type == 'hex' then
			elseif type == 'rgba' then
				return self.color.r, self.color.g, self.color.b, self.color.a
			else
				-- object
				return self.color;
			end
		end

		button:SetScript('OnClick', function(btn)
			StdUi:ColorPickerFrame(
				btn.color.r,
				btn.color.g,
				btn.color.b,
				btn.color.a,
				function(cpf)
					btn:SetColor(cpf:GetColorRGBA());
				end
			);
		end);

		if r then
			button:SetColor(r, g, b, a);
		end

		return button;
	end

	StdUi:RegisterModule(module, version);
end 

init_ColorPicker()


--------------------------------------
-- Widgets: ContextMenu.lua
--------------------------------------
local function init_ContextMenu()
	local module, version = 'ContextMenu', 2;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	---@type ContextMenu
	StdUi.ContextMenuMethods = {

		CloseMenu = function(self)
			self:CloseSubMenus();
			self:Hide();
		end,

		CloseSubMenus = function(self)
			for i = 1, #self.optionFrames do
				local optionFrame = self.optionFrames[i];
				if optionFrame.childContext then
					optionFrame.childContext:CloseMenu();
				end
			end
		end,

		HookRightClick = function(self)
			local parent = self:GetParent();
			if parent then
				parent:HookScript('OnMouseUp', function(par, button)

					if button == 'RightButton' then
						local uiScale = UIParent:GetScale();
						local cursorX, cursorY = GetCursorPosition();

						cursorX = cursorX / uiScale;
						cursorY = cursorY / uiScale;

						self:ClearAllPoints();

						if self:IsShown() then
							self:Hide();
						else
							self:SetPoint('TOPLEFT', nil, 'BOTTOMLEFT', cursorX, cursorY);
							self:Show();
						end
					end
				end);
			end
		end,

		HookChildrenClick = function(self)

		end,

		CreateItem = function(parent, data, i)
			local itemFrame;

			if data.title then
				itemFrame = parent.stdUi:Frame(parent, nil, 20);
				itemFrame.text = parent.stdUi:Label(itemFrame);
				parent.stdUi:GlueLeft(itemFrame.text, itemFrame, 0, 0, true);
			elseif data.isSeparator then
				itemFrame = parent.stdUi:Frame(parent, nil, 20);
				itemFrame.texture = parent.stdUi:Texture(itemFrame, nil, 8,
					[[Interface\COMMON\UI-TooltipDivider-Transparent]]);
				itemFrame.texture:SetPoint('CENTER');
				itemFrame.texture:SetPoint('LEFT');
				itemFrame.texture:SetPoint('RIGHT');
			elseif data.checkbox then
				itemFrame = parent.stdUi:Checkbox(parent, '');
			elseif data.radio then
				itemFrame = parent.stdUi:Radio(parent, '', data.radioGroup);
			elseif data.text then
				itemFrame = parent.stdUi:HighlightButton(parent, nil, 20);
			end

			if not data.isSeparator then
				itemFrame.text:SetJustifyH('LEFT');
			end

			if not data.isSeparator and data.children then
				itemFrame.icon = parent.stdUi:Texture(itemFrame, 10, 10, [[Interface\Buttons\SquareButtonTextures]]);
				itemFrame.icon:SetTexCoord(0.42187500, 0.23437500, 0.01562500, 0.20312500);
				parent.stdUi:GlueRight(itemFrame.icon, itemFrame, -4, 0, true);

				itemFrame.childContext = parent.stdUi:ContextMenu(parent, data.children, true, parent.level + 1);
				itemFrame.parentContext = parent;
				-- this will keep propagating mainContext thru all children
				itemFrame.mainContext = parent.mainContext;

				itemFrame:HookScript('OnEnter', function(itemFrame, button)
					parent:CloseSubMenus();

					itemFrame.childContext:ClearAllPoints();
					itemFrame.childContext:SetPoint('TOPLEFT', itemFrame, 'TOPRIGHT', 0, 0);
					itemFrame.childContext:Show();
				end);
			end

			if data.events then
				for eventName, eventHandler in pairs(data.events) do
					itemFrame:SetScript(eventName, eventHandler);
				end
			end

			if data.callback then
				itemFrame:SetScript('OnMouseUp', function(frame, button)
					if button == 'LeftButton' then
						data.callback(frame, frame.parentContext)
					end
				end)
			end

			if data.custom then
				for key, value in pairs(data.custom) do
					itemFrame[key] = value;
				end
			end

			return itemFrame;
		end,

		UpdateItem = function(parent, itemFrame, data, i)
			local padding = parent.padding;

			if data.title then
				itemFrame.text:SetText(data.title);
				parent.stdUi:ButtonAutoWidth(itemFrame);
			elseif data.checkbox or data.radio then
				itemFrame.text:SetText(data.checkbox or data.radio);
				itemFrame:AutoWidth();
				if data.value then
					itemFrame:SetValue(data.value);
				end
			elseif data.text then
				itemFrame:SetText(data.text);
				parent.stdUi:ButtonAutoWidth(itemFrame);
			end

			if data.children then
				-- add arrow size
				itemFrame:SetWidth(itemFrame:GetWidth() + 16);
			end

			if (parent:GetWidth() -  padding * 2) < itemFrame:GetWidth() then
				parent:SetWidth(itemFrame:GetWidth() + padding * 2);
			end

			itemFrame:SetPoint('LEFT', padding, 0);
			itemFrame:SetPoint('RIGHT', -padding, 0);

			if data.color and not data.isSeparator then
				itemFrame.text:SetTextColor(unpack(data.color));
			end
		end,

		DrawOptions = function(self, options)
			if not self.optionFrames then
				self.optionFrames = {};
			end

			local _, totalHeight = self.stdUi:ObjectList(
				self,
				self.optionFrames,
				self.CreateItem,
				self.UpdateItem,
				options,
				0,
				self.padding,
				-self.padding
			);

			self:SetHeight(totalHeight + self.padding);
		end,

		StartHideCounter = function(self)
			if self.timer then
				self.timer:Cancel();
			end
			self.timer = C_Timer:NewTimer(3, self.TimerCallback);
		end,

		StopHideCounter = function()

		end
	};

	StdUi.ContextMenuEvents = {
		OnEnter = function(self)

		end,
		OnLeave = function(self)

		end
	};

	function StdUi:ContextMenu(parent, options, stopHook, level)
		---@class ContextMenu
		local panel = self:Panel(parent);
		panel.stdUi = self;
		panel.level = level or 1;
		panel.padding = 16;

		panel:SetFrameStrata('FULLSCREEN_DIALOG');

		for methodName, method in pairs(self.ContextMenuMethods) do
			panel[methodName] = method;
		end

		for eventName, eventHandler in pairs(self.ContextMenuEvents) do
			panel:SetScript(eventName, eventHandler);
		end

		panel:DrawOptions(options);

		if panel.level == 1 then
			-- self reference for children
			panel.mainContext = panel;
			if not stopHook then
				panel:HookRightClick();
			end
		end

		panel:Hide();

		return panel;
	end

	StdUi:RegisterModule(module, version);
end 

init_ContextMenu()


--------------------------------------
-- Widgets: Dropdown.lua
--------------------------------------
local function init_Dropdown()
	local module, version = 'Dropdown', 1;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	-- reference to all other dropdowns to close them when new one opens
	local dropdowns = {};

	--- Creates a single level dropdown menu
	--- local options = {
	---		{text = 'some text', value = 10},
	---		{text = 'some text2', value = 11},
	---		{text = 'some text3', value = 12},
	--- }
	function StdUi:Dropdown(parent, width, height, options, value, multi)
		local this = self;
		local dropdown = self:Button(parent, width, height, '');
		dropdown.text:SetJustifyH('LEFT');
		-- make it shorter because of arrow
		dropdown.text:ClearAllPoints();
		self:GlueAcross(dropdown.text, dropdown, 2, -2, -16, 2);
		
		local dropTex = self:Texture(dropdown, 15, 15, [[Interface\Buttons\SquareButtonTextures]]);
		dropTex:SetTexCoord(0.45312500, 0.64062500, 0.20312500, 0.01562500);
		self:GlueRight(dropTex, dropdown, -2, 0, true);

		local optsFrame = self:FauxScrollFrame(dropdown, dropdown:GetWidth(), 200, 10, 20);
		self:GlueBelow(optsFrame, dropdown, 0, 0, 'LEFT');
		dropdown:SetFrameLevel(optsFrame:GetFrameLevel() + 1);
		optsFrame:Hide();

		dropdown.multi = multi;
		dropdown.optsFrame = optsFrame;
		dropdown.dropTex = dropTex;
		dropdown.options = options;

		function dropdown:ShowOptions()
			for i = 1, #dropdowns do
				dropdowns[i]:HideOptions();
			end

			self.optsFrame:Show();
			self.optsFrame:Update();
		end

		function dropdown:HideOptions()
			self.optsFrame:Hide();
		end

		function dropdown:ToggleOptions()
			if self.optsFrame:IsShown() then
				self:HideOptions();
			else
				self:ShowOptions();
			end
		end

		function dropdown:SetPlaceholder(placeholderText)
			if self:GetText() == '' or self:GetText() == self.placeholder then
				self:SetText(placeholderText);
			end

			self.placeholder = placeholderText;
		end

		function dropdown:SetOptions(options)
			self.options = options;
			local optionsHeight = #options * 20;
			local scrollChild = self.optsFrame.scrollChild;

			self.optsFrame:SetHeight(math.min(optionsHeight + 4, 200));
			scrollChild:SetHeight(optionsHeight);

			local buttonCreate = function(parent, i)
				local optionButton;
				if multi then
					optionButton = this:Checkbox(parent, '', parent:GetWidth(), 20);
				else
					optionButton = this:HighlightButton(parent, parent:GetWidth(), 20, '');
					optionButton.text:SetJustifyH('LEFT');
				end

				optionButton.dropdown = self;
				optionButton:SetFrameLevel(parent:GetFrameLevel() + 2);
				if not self.multi then
					optionButton:SetScript('OnClick', function(self)
						self.dropdown:SetValue(self.value, self:GetText());
						self.dropdown.optsFrame:Hide();
					end);
				else
					optionButton.OnValueChanged = function(checkbox, isChecked)
						checkbox.dropdown:ToggleValue(checkbox.value, isChecked);
					end
				end

				return optionButton;
			end;

			local buttonUpdate = function(parent, itemFrame, data)
				itemFrame:SetText(data.text);
				if multi then
					itemFrame:SetValue(data.value);
				else
					itemFrame.value = data.value;
				end
			end;

			if not scrollChild.items then
				scrollChild.items = {};
			end

			this:ObjectList(scrollChild, scrollChild.items, buttonCreate, buttonUpdate, options);
			self.optsFrame:UpdateItemsCount(#options);
		end

		function dropdown:ToggleValue(value, state)
			assert(self.multi, 'Single dropdown cannot have more than one value!');

			if state then
				-- we are toggling it on
				if not tContains(self.value, value) then
					tinsert(self.value, value);
				end
			else
				-- we are removing it from table
				if tContains(self.value, value) then
					tDeleteItem(self.value, value);
				end
			end

			self:SetValue(self.value);
		end

		function dropdown:SetValue(value, text)
			self.value = value;

			if text then
				self:SetText(text);
			else
				self:SetText(self:FindValueText(value));
			end

			if self.OnValueChanged then
				self.OnValueChanged(self, value, self:GetText());
			end
		end

		function dropdown:GetValue()
			return self.value;
		end

		function dropdown:FindValueText(value)
			if type(value) ~= 'table' then
				for i = 1, #self.options do
					local opt = self.options[i];

					if opt.value == value then
						return opt.text;
					end
				end

				return self.placeholder or '';
			else
				local result = '';

				for i = 1, #self.options do
					local opt = self.options[i];

					for x = 1, #value do
						if value[x] == opt.value then
							if result == '' then
								result = opt.text;
							else
								result = result .. ', ' .. opt.text;
							end
						end
					end
				end

				if result ~= '' then
					return result
				else
					return self.placeholder or '';
				end
			end
		end

		if options then
			dropdown:SetOptions(options);
		end

		if value then
			dropdown:SetValue(value);
		elseif multi then
			dropdown.value = {};
		end

		dropdown:SetScript('OnClick', function(self)
			self:ToggleOptions();
		end);

		tinsert(dropdowns, dropdown);

		return dropdown;
	end

	StdUi:RegisterModule(module, version);
end 

init_Dropdown()


--------------------------------------
-- Widgets: EditBox.lua
--------------------------------------
local function init_EditBox()
	local module, version = 'EditBox', 3;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	--- @return EditBox
	function StdUi:SimpleEditBox(parent, width, height, text)
		local this = self;
		--- @type EditBox
		local editBox = CreateFrame('EditBox', nil, parent);
		self:InitWidget(editBox);

		editBox:SetTextInsets(3, 3, 3, 3);
		editBox:SetFontObject(ChatFontNormal);
		editBox:SetAutoFocus(false);

		editBox:SetScript('OnEscapePressed', function (self)
			self:ClearFocus();
		end);

		function editBox:SetFontSize(newSize)
			self:SetFont(self:GetFont(), newSize, this.config.font.effect);
		end

		if text then
			editBox:SetText(text);
		end

		self:HookDisabledBackdrop(editBox);
		self:HookHoverBorder(editBox);
		self:ApplyBackdrop(editBox);
		self:SetObjSize(editBox, width, height);

		return editBox;
	end

	function StdUi:SearchEditBox(parent, width, height, placeholderText)
		local editBox = self:SimpleEditBox(parent, width, height, '');

		local icon = self:Texture(editBox, 14, 14, [[Interface\Common\UI-Searchbox-Icon]]);
		local c = self.config.font.color.disabled;
		icon:SetVertexColor(c.r, c.g, c.b, c.a);
		local label = self:Label(editBox, placeholderText);
		self:SetTextColor(label, 'disabled');

		self:GlueLeft(icon, editBox, 5, 0, true);
		self:GlueRight(label, icon, 2, 0);

		editBox.placeholder = {
			icon = icon,
			label = label
		};

		editBox:SetScript('OnTextChanged', function(self)
			if strlen(self:GetText()) > 0 then
				self.placeholder.icon:Hide();
				self.placeholder.label:Hide();
			else
				self.placeholder.icon:Show();
				self.placeholder.label:Show();
			end

			if self.OnValueChanged then
				self:OnValueChanged(self:GetText());
			end
		end);

		return editBox;
	end

	--- @return EditBox
	function StdUi:EditBox(parent, width, height, text, validator)
		validator = validator or StdUi.Util.editBoxValidator;

		local editBox = self:SimpleEditBox(parent, width, height, text);

		function editBox:GetValue()
			return self.value;
		end;

		function editBox:SetValue(value)
			self.value = value;
			self:SetText(value);
			self:Validate();
			self.button:Hide();
		end;

		function editBox:IsValid()
			return self.isValid;
		end;

		function editBox:Validate()
			self.isValidated = true;
			self.isValid = validator(self);

			if self.isValid then
				if self.button then
					self.button:Hide();
				end

				if self.OnValueChanged and tostring(self.lastValue) ~= tostring(self.value) then
					self:OnValueChanged(self.value);
					self.lastValue = self.value;
				end
			end
			self.isValidated = false;
		end;

		local button = self:Button(editBox, 40, height - 4, OKAY);
		button:SetPoint('RIGHT', -2, 0);
		button:Hide();
		button.editBox = editBox;
		editBox.button = button;

		button:SetScript('OnClick', function(self)
			self.editBox:Validate(self.editBox);
		end);

		editBox:SetScript('OnEnterPressed', function(self)
			self:Validate();
		end)

		editBox:SetScript('OnTextChanged', function(self, isUserInput)
			local value = StdUi.Util.stripColors(self:GetText());
			if tostring(value) ~= tostring(self.value) then
				if not self.isValidated and self.button and isUserInput then
					self.button:Show();
				end
			else
				self.button:Hide();
			end
		end);

		return editBox;
	end

	function StdUi:NumericBox(parent, width, height, text, validator)
		validator = validator or self.Util.numericBoxValidator;

		local editBox = self:EditBox(parent, width, height, text, validator);
		editBox:SetNumeric(true);

		function editBox:SetMaxValue(value)
			self.maxValue = value;
			self:Validate();
		end;

		function editBox:SetMinValue(value)
			self.minValue = value;
			self:Validate();
		end;

		function editBox:SetMinMaxValue(min, max)
			self.minValue = min;
			self.maxValue = max;
			self:Validate();
		end

		return editBox;
	end

	function StdUi:MoneyBox(parent, width, height, text, validator)
		validator = validator or self.Util.moneyBoxValidator;

		local editBox = self:EditBox(parent, width, height, text, validator);
		editBox:SetMaxLetters(20);

		local formatMoney = StdUi.Util.formatMoney;
		function editBox:SetValue(value)
			self.value = value;
			local formatted = formatMoney(value);
			self:SetText(formatted);
			self:Validate();
			self.button:Hide();
		end;

		return editBox;
	end

	function StdUi:MultiLineBox(parent, width, height, text)
		local editBox = CreateFrame('EditBox');
		local panel, scrollFrame = self:ScrollFrame(parent, width, height, editBox);

		scrollFrame.target = panel;
		editBox.target = panel;

		self:ApplyBackdrop(panel, 'button');
		self:HookHoverBorder(scrollFrame);
		self:HookHoverBorder(editBox);

		editBox:SetWidth(scrollFrame:GetWidth());
		--editBox:SetHeight(scrollFrame:GetHeight());

		editBox:SetTextInsets(3, 3, 3, 3);
		editBox:SetFontObject(ChatFontNormal);
		editBox:SetAutoFocus(false);
		editBox:SetScript('OnEscapePressed', editBox.ClearFocus);
		editBox:SetMultiLine(true);
		editBox:EnableMouse(true);
		editBox:SetAutoFocus(false);
		editBox:SetCountInvisibleLetters(false);
		editBox:SetAllPoints();

		editBox.scrollFrame = scrollFrame;
		editBox.panel = panel;

		if text then
			editBox:SetText(text);
		end

		editBox:SetScript('OnCursorChanged', function(self, _, y, _, cursorHeight)
			local sf, y = self.scrollFrame, -y;
			local offset = sf:GetVerticalScroll();

			if y < offset then
				sf:SetVerticalScroll(y);
			else
				y = y + cursorHeight - sf:GetHeight() + 6; --text insets
				if y > offset then
					sf:SetVerticalScroll(math.ceil(y));
				end
			end
		end)

		editBox:SetScript('OnTextChanged', function(self)
			if self.OnValueChanged then
				self:OnValueChanged(self:GetText());
			end
		end);

		scrollFrame:HookScript('OnMouseDown', function(sf, button)
			sf.scrollChild:SetFocus();
		end);

		scrollFrame:HookScript('OnVerticalScroll', function(self, offset)
			self.scrollChild:SetHitRectInsets(0, 0, offset, self.scrollChild:GetHeight() - offset - self:GetHeight());
		end);


		return editBox;
	end

	StdUi:RegisterModule(module, version);
end 

init_EditBox()


--------------------------------------
-- Widgets: Label.lua
--------------------------------------
local function init_Label()
	local module, version = 'Label', 2;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	--- @return FontString
	function StdUi:FontString(parent, text, inherit)
		local this = self;
		local fs = parent:CreateFontString(nil, self.config.font.strata, inherit or 'GameFontNormal');

		fs:SetText(text);
		fs:SetJustifyH('LEFT');
		fs:SetJustifyV('MIDDLE');

		function fs:SetFontSize(newSize)
			self:SetFont(self:GetFont(), newSize);
		end

		return fs;
	end

	--- @return FontString
	function StdUi:Label(parent, text, size, inherit, width, height)
		local fs = self:FontString(parent, text, inherit);
		if size then
			fs:SetFontSize(size);
		end

		self:SetTextColor(fs, 'normal');
		self:SetObjSize(fs, width, height);

		return fs;
	end

	--- @return FontString
	function StdUi:Header(parent, text, size, inherit, width, height)
		local fs = self:Label(parent, text, size, inherit or 'GameFontNormalLarge', width, height);

		self:SetTextColor(fs, 'header');

		return fs;
	end

	--- @return FontString
	function StdUi:AddLabel(parent, object, text, labelPosition, labelWidth)
		local labelHeight = (self.config.font.size) + 4;
		local label = self:Label(parent, text, self.config.font.size, nil, labelWidth, labelHeight);

		if labelPosition == 'TOP' or labelPosition == nil then
			self:GlueAbove(label, object, 0, 4, 'LEFT');
		elseif labelPosition == 'RIGHT' then
			self:GlueRight(label, object, 4, 0);
		else -- labelPosition == 'LEFT'
			label:SetWidth(labelWidth or label:GetStringWidth())
			self:GlueLeft(label, object, -4, 0);
		end

		object.label = label;

		return label;
	end

	StdUi:RegisterModule(module, version);
end 

init_Label()


--------------------------------------
-- Widgets: ProgressBar.lua
--------------------------------------
local function init_ProgressBar()
	local module, version = 'ProgressBar', 2;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	--- @return StatusBar
	function StdUi:ProgressBar(parent, width, height, vertical)
		vertical = vertical or false;

		local progressBar = CreateFrame('StatusBar', nil, parent);
		progressBar:SetStatusBarTexture(self.config.backdrop.texture);
		progressBar:SetStatusBarColor(
			self.config.progressBar.color.r,
			self.config.progressBar.color.g,
			self.config.progressBar.color.b,
			self.config.progressBar.color.a
		);
		self:SetObjSize(progressBar, width, height);

		progressBar.texture = progressBar:GetRegions();
		progressBar.texture:SetDrawLayer('BORDER', -1);

		if (vertical) then
			progressBar:SetOrientation('VERTICAL');
		end

		progressBar.text = self:Label(progressBar, '');
		progressBar.text:SetJustifyH('MIDDLE');
		progressBar.text:SetAllPoints();

		self:ApplyBackdrop(progressBar);

		function progressBar:GetPercentageValue()
			local min, max = self:GetMinMaxValues();
			local value = self:GetValue();
			return (value/max) * 100;
		end

		function progressBar:TextUpdate(min, max, value)
			return Round(self:GetPercentageValue()) .. '%';
		end

		progressBar:SetScript('OnValueChanged', function(self, value)
			local min, max = self:GetMinMaxValues();
			self.text:SetText(self:TextUpdate(min, max, value));
		end);

		progressBar:SetScript('OnMinMaxChanged', function(self)
			local min, max = self:GetMinMaxValues();
			local value = self:GetValue();
			self.text:SetText(self:TextUpdate(min, max, value));
		end);

		return progressBar;
	end

	StdUi:RegisterModule(module, version);
end 

init_ProgressBar()


--------------------------------------
-- Widgets: Scroll.lua
--------------------------------------
local function init_Scroll()
	local module, version = 'Scroll', 2;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	StdUi.ScrollBarEvents = {
		UpButtonOnClick = function(self)
			local scrollBar = self.scrollBar;
			local scrollStep = scrollBar.ScrollFrame.scrollStep or (scrollBar.ScrollFrame:GetHeight() / 2);
			scrollBar:SetValue(scrollBar:GetValue() - scrollStep);
		end,
		DownButtonOnClick = function(self)
			local scrollBar = self.scrollBar;
			local scrollStep = scrollBar.ScrollFrame.scrollStep or (scrollBar.ScrollFrame:GetHeight() / 2);
			scrollBar:SetValue(scrollBar:GetValue() + scrollStep);
		end,
		OnValueChanged = function(self, value)
			self.ScrollFrame:SetVerticalScroll(value);
		end
	};

	StdUi.ScrollFrameEvents = {
		OnLoad = function(self)
			local scrollbar = self.ScrollBar;

			scrollbar:SetMinMaxValues(0, 0);
			scrollbar:SetValue(0);
			self.offset = 0;

			local scrollDownButton = scrollbar.ScrollDownButton;
			local scrollUpButton = scrollbar.ScrollUpButton;

			scrollDownButton:Disable();
			scrollUpButton:Disable();

			if self.scrollBarHideable then
				scrollbar:Hide();
				scrollDownButton:Hide();
				scrollUpButton:Hide();
			else
				scrollDownButton:Disable();
				scrollUpButton:Disable();
				scrollDownButton:Show();
				scrollUpButton:Show();
			end

			if self.noScrollThumb then
				scrollbar.ThumbTexture:Hide();
			end
		end,

		OnMouseWheel = function(self, value, scrollBar)
			scrollBar = scrollBar or self.ScrollBar;
			local scrollStep = scrollBar.scrollStep or scrollBar:GetHeight() / 2;

			if value > 0 then
				scrollBar:SetValue(scrollBar:GetValue() - scrollStep);
			else
				scrollBar:SetValue(scrollBar:GetValue() + scrollStep);
			end
		end,

		OnScrollRangeChanged = function(self, xrange, yrange)
			local scrollbar = self.ScrollBar;
			if ( not yrange ) then
				yrange = self:GetVerticalScrollRange();
			end

			-- Accounting for very small ranges
			yrange = math.floor(yrange);

			local value = math.min(scrollbar:GetValue(), yrange);
			scrollbar:SetMinMaxValues(0, yrange);
			scrollbar:SetValue(value);

			local scrollDownButton = scrollbar.ScrollDownButton;
			local scrollUpButton = scrollbar.ScrollUpButton;
			local thumbTexture = scrollbar.ThumbTexture;

			if ( yrange == 0 ) then
				if ( self.scrollBarHideable ) then
					scrollbar:Hide();
					scrollDownButton:Hide();
					scrollUpButton:Hide();
					thumbTexture:Hide();
				else
					scrollDownButton:Disable();
					scrollUpButton:Disable();
					scrollDownButton:Show();
					scrollUpButton:Show();
					if ( not self.noScrollThumb ) then
						thumbTexture:Show();
					end
				end
			else
				scrollDownButton:Show();
				scrollUpButton:Show();
				scrollbar:Show();
				if ( not self.noScrollThumb ) then
					thumbTexture:Show();
				end
				-- The 0.005 is to account for precision errors
				if ( yrange - value > 0.005 ) then
					scrollDownButton:Enable();
				else
					scrollDownButton:Disable();
				end
			end
		end,

		OnVerticalScroll = function(self, offset)
			local scrollBar = self.ScrollBar;
			scrollBar:SetValue(offset);

			local min, max = scrollBar:GetMinMaxValues();
			scrollBar.ScrollUpButton:SetEnabled(offset ~= 0);
			scrollBar.ScrollDownButton:SetEnabled((scrollBar:GetValue() - max) ~= 0);
		end
	}

	StdUi.FauxScrollFrameMethods = {
		GetChildFrames = function(frame)
			local scrollBar = frame.ScrollBar;
			local ScrollChildFrame = frame.scrollChild;

			if not frame.ScrollChildFrame then
				frame.ScrollChildFrame = ScrollChildFrame;
			end

			if not frame.ScrollBar then
				frame.ScrollBar = scrollBar;
			end

			return scrollBar, ScrollChildFrame, scrollBar.ScrollUpButton, scrollBar.ScrollDownButton;
		end,

		GetOffset = function(frame)
			return frame.offset or 0;
		end,

		OnVerticalScroll = function(self, value, itemHeight, updateFunction)
			local scrollBar = self.ScrollBar;
			itemHeight = itemHeight or self.lineHeight;

			scrollBar:SetValue(value);
			self.offset = floor((value / itemHeight) + 0.5);
			if (updateFunction) then
				updateFunction(self);
			end
		end,

		Update = function(frame, numItems, numToDisplay, buttonHeight)
			local scrollBar, scrollChildFrame, scrollUpButton, scrollDownButton =
				StdUi.FauxScrollFrameMethods.GetChildFrames(frame);

			local showScrollBar;
			if (numItems > numToDisplay) then
				frame:Show();
				showScrollBar = 1;
			else
				scrollBar:SetValue(0);
				--frame:Hide(); --TODO: Need to rethink it, so far its left commented out because it breaks dropdown
			end

			if (frame:IsShown()) then
				local scrollFrameHeight = 0;
				local scrollChildHeight = 0;

				if (numItems > 0) then
					scrollFrameHeight = (numItems - numToDisplay) * buttonHeight;
					scrollChildHeight = numItems * buttonHeight;
					if (scrollFrameHeight < 0) then
						scrollFrameHeight = 0;
					end
					scrollChildFrame:Show();
				else
					scrollChildFrame:Hide();
				end

				local maxRange = (numItems - numToDisplay) * buttonHeight;
				if (maxRange < 0) then
					maxRange = 0;
				end

				scrollBar:SetMinMaxValues(0, maxRange);
				scrollBar:SetValueStep(buttonHeight);
				scrollBar:SetStepsPerPage(numToDisplay - 1);
				scrollChildFrame:SetHeight(scrollChildHeight);

				-- Arrow button handling
				if (scrollBar:GetValue() == 0) then
					scrollUpButton:Disable();
				else
					scrollUpButton:Enable();
				end

				if ((scrollBar:GetValue() - scrollFrameHeight) == 0) then
					scrollDownButton:Disable();
				else
					scrollDownButton:Enable();
				end
			end

			return showScrollBar;
		end,
	}

	function StdUi:ScrollFrame(parent, width, height, scrollChild)
		local panel = self:Panel(parent, width, height);
		local scrollBarWidth = 16;

		local scrollFrame = CreateFrame('ScrollFrame', nil, panel);
		scrollFrame:SetScript('OnScrollRangeChanged', StdUi.ScrollFrameEvents.OnScrollRangeChanged);
		scrollFrame:SetScript('OnVerticalScroll', StdUi.ScrollFrameEvents.OnVerticalScroll);
		scrollFrame:SetScript('OnMouseWheel', StdUi.ScrollFrameEvents.OnMouseWheel);

		local scrollBar = self:ScrollBar(panel, scrollBarWidth);
		scrollBar:SetScript('OnValueChanged', StdUi.ScrollBarEvents.OnValueChanged);
		scrollBar.ScrollDownButton:SetScript('OnClick', StdUi.ScrollBarEvents.DownButtonOnClick);
		scrollBar.ScrollUpButton:SetScript('OnClick', StdUi.ScrollBarEvents.UpButtonOnClick);

		scrollFrame.ScrollBar = scrollBar;
		scrollBar.ScrollFrame = scrollFrame;

		--scrollFrame:SetScript('OnLoad', StdUi.ScrollFrameEvents.OnLoad);-- LOL, no wonder it wasnt working
		StdUi.ScrollFrameEvents.OnLoad(scrollFrame);

		scrollFrame.panel = panel;
		scrollFrame:ClearAllPoints();
		scrollFrame:SetSize(width - scrollBarWidth - 5, height - 4); -- scrollbar width and margins
		self:GlueAcross(scrollFrame, panel, 2, -2, -scrollBarWidth - 2, 2);

		scrollBar.panel:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', -2, - 2);
		scrollBar.panel:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', -2, 2);

		if not scrollChild then
			scrollChild = CreateFrame('Frame', nil, scrollFrame);
			scrollChild:SetWidth(scrollFrame:GetWidth());
			scrollChild:SetHeight(scrollFrame:GetHeight());
		else
			scrollChild:SetParent(scrollFrame);
		end

		scrollFrame:SetScrollChild(scrollChild);
		scrollFrame:EnableMouse(true);
		scrollFrame:SetClampedToScreen(true);
		scrollFrame:SetClipsChildren(true);

		scrollChild:SetPoint('RIGHT', scrollFrame, 'RIGHT', 0, 0);

		scrollFrame.scrollChild = scrollChild;

		panel.scrollFrame = scrollFrame;
		panel.scrollChild = scrollChild;
		panel.scrollBar = scrollBar;

		return panel, scrollFrame, scrollChild, scrollBar;
	end

	--- Works pretty much the same as scroll frame however it does not have smooth scroll and only display a certain amount
	--- of items
	function StdUi:FauxScrollFrame(parent, width, height, displayCount, lineHeight, scrollChild)
		local this = self;
		local panel, scrollFrame, scrollChild, scrollBar = self:ScrollFrame(parent, width, height, scrollChild);

		scrollFrame.lineHeight = lineHeight;
		scrollFrame.displayCount = displayCount;

		scrollFrame:SetScript('OnVerticalScroll', function(frame, value)
			this.FauxScrollFrameMethods.OnVerticalScroll(frame, value, lineHeight, function ()
				this.FauxScrollFrameMethods.Update(frame, panel.itemCount or #scrollChild.items, displayCount, lineHeight);
			end);
		end);

		function panel:Update()
			this.FauxScrollFrameMethods.Update(self.scrollFrame, panel.itemCount or #scrollChild.items, displayCount, lineHeight);
		end

		function panel:UpdateItemsCount(newCount)
			self.itemCount = newCount;
			this.FauxScrollFrameMethods.Update(self.scrollFrame, newCount, displayCount, lineHeight);
		end

		return panel, scrollFrame, scrollChild, scrollBar;
	end

	StdUi:RegisterModule(module, version);
end 

init_Scroll()


--------------------------------------
-- Widgets: ScrollTable.lua
--------------------------------------
local function init_ScrollTable()
	local module, version = 'ScrollTable', 4;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	local lrpadding = 2.5;

	--- Public methods of ScrollTable
	local methods = {

		-------------------------------------------------------------
		--- Basic Methods
		-------------------------------------------------------------

		SetAutoHeight = function(self)
			self:SetHeight((self.numberOfRows * self.rowHeight) + 10);
			self:Refresh();
		end,

		SetAutoWidth = function(self)
			local width = 13;
			for num, col in pairs(self.columns) do
				width = width + col.width;
			end
			self:SetWidth(width + 20);
			self:Refresh();
		end,

		ScrollToLine = function(self, line)
			line = Clamp(line, 1, #self.filtered - self.numberOfRows + 1);

			self.stdUi.FauxScrollFrameMethods.OnVerticalScroll(
				self.scrollFrame,
				self.rowHeight * (line - 1),
				self.rowHeight, function()
					self:Refresh();
				end
			);
		end,

		-------------------------------------------------------------
		--- Drawing Methods
		-------------------------------------------------------------

		--- Set the column info for the scrolling table
		--- @usage st:SetColumns(columns)
		SetColumns = function(self, columns)
			local table = self; -- reference saved for closure
			self.columns = columns;

			local columnHeadFrame = self.head;
			
			if not columnHeadFrame then
				columnHeadFrame = CreateFrame('Frame', nil, self);
				columnHeadFrame:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 4, 0);
				columnHeadFrame:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', -4, 0);
				columnHeadFrame:SetHeight(self.rowHeight);
				columnHeadFrame.columns = {};
				self.head = columnHeadFrame;
			end

			for i = 1, #columns do
				local columnFrame = columnHeadFrame.columns[i];
				if not columnHeadFrame.columns[i] then
					columnFrame = self.stdUi:HighlightButton(columnHeadFrame);
					columnFrame:SetPushedTextOffset(0, 0);

					columnFrame.arrow = self.stdUi:Texture(columnFrame, 8, 8, [[Interface\Buttons\UI-SortArrow]]);
					columnFrame.arrow:Hide();

					if self.headerEvents then
						for event, handler in pairs(self.headerEvents) do
							columnFrame:SetScript(event, function(cellFrame, ...)
								table:FireHeaderEvent(event, handler, columnFrame, columnHeadFrame, i, ...);
							end);
						end
					end

					columnHeadFrame.columns[i] = columnFrame;
				end

				local align = columns[i].align or 'LEFT';
				columnFrame.text:SetJustifyH(align);
				columnFrame.text:SetText(columns[i].name);

				if align == 'LEFT' then
					columnFrame.arrow:ClearAllPoints();
					self.stdUi:GlueRight(columnFrame.arrow, columnFrame, 0, 0, true);
				else
					columnFrame.arrow:ClearAllPoints();
					self.stdUi:GlueLeft(columnFrame.arrow, columnFrame, 5, 0, true);
				end

				if columns[i].sortable == false and columns[i].sortable ~= nil then

				else

				end

				if i > 1 then
					columnFrame:SetPoint('LEFT', columnHeadFrame.columns[i - 1], 'RIGHT', 0, 0);
				else
					columnFrame:SetPoint('LEFT', columnHeadFrame, 'LEFT', 2, 0);
				end

				columnFrame:SetHeight(self.rowHeight);
				columnFrame:SetWidth(columns[i].width);
			end

			self:SetDisplayRows(self.numberOfRows, self.rowHeight);
			self:SetAutoWidth();
		end,

		--- Set the number and height of displayed rows
		--- @usage st:SetDisplayRows(10, 15)
		SetDisplayRows = function(self, numberOfRows, rowHeight)
			local table = self; -- reference saved for closure
			-- should always set columns first
			self.numberOfRows = numberOfRows;
			self.rowHeight = rowHeight;

			if not self.rows then
				self.rows = {};
			end

			for i = 1, numberOfRows do
				local rowFrame = self.rows[i];

				if not rowFrame then
					rowFrame = CreateFrame('Button', nil, self);
					self.rows[i] = rowFrame;

					if i > 1 then
						rowFrame:SetPoint('TOPLEFT', self.rows[i - 1], 'BOTTOMLEFT', 0, 0);
						rowFrame:SetPoint('TOPRIGHT', self.rows[i - 1], 'BOTTOMRIGHT', 0, 0);
					else
						rowFrame:SetPoint('TOPLEFT', self.scrollFrame, 'TOPLEFT', 1, -1);
						rowFrame:SetPoint('TOPRIGHT', self.scrollFrame, 'TOPRIGHT', -1, -1);
					end

					rowFrame:SetHeight(rowHeight);
				end

				if not rowFrame.columns then
					rowFrame.columns = {};
				end

				for j = 1, #self.columns do
					local columnData = self.columns[j];

					local cell = rowFrame.columns[j];
					if not cell then
						cell = CreateFrame('Button', nil, rowFrame);
						cell.text = self.stdUi:FontString(cell, '');

						rowFrame.columns[j] = cell;

						local align = columnData.align or 'LEFT';

						cell.text:SetJustifyH(align);
						cell:EnableMouse(true);
						cell:RegisterForClicks('AnyUp');

						if self.cellEvents then
							for event, handler in pairs(self.cellEvents) do
								cell:SetScript(event, function(cellFrame, ...)
									if table.offset then
										local rowIndex = table.filtered[i + table.offset];
										local rowData = table:GetRow(rowIndex);
										table:FireCellEvent(event, handler, cellFrame, rowFrame, rowData, columnData,
										rowIndex, ...);
									end
								end);
							end
						end

						-- override a column based events
						if columnData.events then
							for event, handler in pairs(columnData.events) do

								cell:SetScript(event, function(cellFrame, ...)
									if table.offset then
										local rowIndex = table.filtered[i + table.offset];
										local rowData = table:GetRow(rowIndex);
										table:FireCellEvent(event, handler, cellFrame, rowFrame, rowData, columnData,
												rowIndex, ...);
									end
								end);
							end
						end
					end

					if j > 1 then
						cell:SetPoint('LEFT', rowFrame.columns[j - 1], 'RIGHT', 0, 0);
					else
						cell:SetPoint('LEFT', rowFrame, 'LEFT', 2, 0);
					end

					cell:SetHeight(rowHeight);
					cell:SetWidth(self.columns[j].width);

					cell.text:SetPoint('TOP', cell, 'TOP', 0, 0);
					cell.text:SetPoint('BOTTOM', cell, 'BOTTOM', 0, 0);
					cell.text:SetWidth(self.columns[j].width - 2 * lrpadding);
				end

				j = #self.columns + 1;
				col = rowFrame.columns[j];
				while col do
					col:Hide();
					j = j + 1;
					col = rowFrame.columns[j];
				end
			end

			for i = numberOfRows + 1, #self.rows do
				self.rows[i]:Hide();
			end

			self:SetAutoHeight();
		end,

		-------------------------------------------------------------
		--- Sorting Methods
		-------------------------------------------------------------

		--- Resorts the table using the rules specified in the table column info.
		--- @usage st:SortData()
		SortData = function(self, sortBy)
			-- sanity check
			if not (self.sortTable) or (#self.sortTable ~= #self.data) then
				self.sortTable = {};
			end

			if #self.sortTable ~= #self.data then
				for i = 1, #self.data do
					self.sortTable[i] = i;
				end
			end

			-- go on sorting
			if not sortBy then
				local i = 1;
				while i <= #self.columns and not sortBy do
					if self.columns[i].sort then
						sortBy = i;
					end
					i = i + 1;
				end
			end

			if sortBy then
				table.sort(self.sortTable, function(rowA, rowB)
					local column = self.columns[sortBy];
					if column.compareSort then
						return column.compareSort(self, rowA, rowB, sortBy);
					else
						return self:CompareSort(rowA, rowB, sortBy);
					end
				end);
			end

			self.filtered = self:DoFilter();
			self:Refresh();
			self:UpdateSortArrows(sortBy);
		end,

		--- CompareSort function used to determine how to sort column values. Can be overridden in column data or table data.
		--- @usage used internally.
		CompareSort = function(self, rowA, rowB, sortBy)
			local a = self:GetRow(rowA);
			local b = self:GetRow(rowB);
			local column = self.columns[sortBy];
			local idx = column.index;

			local direction = column.sort or column.defaultSort or 'asc';

			if direction:lower() == 'asc' then
				return a[idx] > b[idx];
			else
				return a[idx] < b[idx];
			end
		end,

		Filter = function(self, rowData)
			return true;
		end,

		--- Set a display filter for the table.
		--- @usage st:SetFilter( function (self, ...) return true end )
		SetFilter = function(self, filter, noSort)
			self.Filter = filter;
			if not noSort then
				self:SortData();
			end
		end,

		DoFilter = function(self)
			local result = {};

			for row = 1, #self.data do
				local realRow = self.sortTable[row];
				local rowData = self:GetRow(realRow);

				if self:Filter(rowData) then
					table.insert(result, realRow);
				end
			end

			return result;
		end,

		-------------------------------------------------------------
		--- Highlight Methods
		-------------------------------------------------------------

		--- Set the row highlight color of a frame ( cell or row )
		--- @usage st:SetHighLightColor(rowFrame, color)
		SetHighLightColor = function(self, frame, color)
			if not frame.highlight then
				frame.highlight = frame:CreateTexture(nil, 'OVERLAY');
				frame.highlight:SetAllPoints(frame);
			end
			if not color then
				frame.highlight:SetColorTexture(0, 0, 0, 0);
			else
				frame.highlight:SetColorTexture(color.r, color.g, color.b, color.a);
			end
		end,


		-------------------------------------------------------------
		--- Selection Methods
		-------------------------------------------------------------

		--- Turn on or off selection on a table according to flag. Will not refresh the table display.
		--- @usage st:EnableSelection(true)
		EnableSelection = function(self, flag)
			self.selectionEnabled = flag;
		end,

		--- Clear the currently selected row. You should not need to refresh the table.
		--- @usage st:ClearSelection()
		ClearSelection = function(self)
			self:SetSelection(nil);
		end,

		--- Sets the currently selected row to 'realRow'. RealRow is the unaltered index of the data row in your table.
		--- You should not need to refresh the table.
		--- @usage st:SetSelection(12)
		SetSelection = function(self, rowIndex)
			self.selected = rowIndex;
			self:Refresh();
		end,

		--- Gets the currently selected row.
		--- Return will be the unaltered index of the data row that is selected.
		--- @usage st:GetSelection()
		GetSelection = function(self)
			return self.selected;
		end,

		--- Gets the currently selected row.
		--- Return will be the unaltered index of the data row that is selected.
		--- @usage st:GetSelection()
		GetSelectedItem = function(self)
			return self:GetRow(self.selected);
		end,

		-------------------------------------------------------------
		--- Data Methods
		-------------------------------------------------------------

		--- Sets the data for the scrolling table
		--- @usage st:SetData(datatable)
		SetData = function(self, data)
			self.data = data;
			self:SortData();
		end,

		--- Returns the data row of the table from the given data row index
		--- @usage used internally.
		GetRow = function(self, rowIndex)
			return self.data[rowIndex];
		end,

		--- Returns the cell data of the given row from the given row and column index
		--- @usage used internally.
		GetCell = function(self, row, col)
			local rowData = row;
			if type(row) == 'number' then
				rowData = self:GetRow(row);
			end

			return rowData[col];
		end,

		--- Checks if a row is currently being shown
		--- @usage st:IsRowVisible(realrow)
		--- @thanks sapu94
		IsRowVisible = function(self, rowIndex)
			return (rowIndex > self.offset and rowIndex <= (self.numberOfRows + self.offset));
		end,

		-------------------------------------------------------------
		--- Update Internal Methods
		-------------------------------------------------------------

		--- Cell update function used to paint each cell.  Can be overridden in column data or table data.
		--- @usage used internally.
		DoCellUpdate = function(table, shouldShow, rowFrame, cellFrame, value, columnData, rowData, rowIndex)
			if shouldShow then
				local format = columnData.format;

				if type(format) == 'function' then
					cellFrame.text:SetText(format(value, rowData, columnData));
				elseif (format == 'money') then
					value = table.stdUi.Util.formatMoney(value);
					cellFrame.text:SetText(value);
				elseif (format == 'number') then
					value = tostring(value);
					cellFrame.text:SetText(value);
				elseif (format == 'icon') then
					if cellFrame.texture then
						cellFrame.texture:SetTexture(value);
					else
						local iconSize = columnData.iconSize or table.rowHeight;
						cellFrame.texture = table.stdUi:Texture(cellFrame, iconSize, iconSize, value);
						cellFrame.texture:SetPoint('CENTER', 0, 0);
					end
				else
					cellFrame.text:SetText(value);
				end

				local color;
				if rowData.color then
					color = rowData.color;
				elseif columnData.color then
					color = columnData.color;
				end

				if type(color) == 'function' then
					color = color(table, value, rowData, columnData);
				end

				if color then
					cellFrame.text:SetTextColor(color.r, color.g, color.b, color.a);
				else
					table.stdUi:SetTextColor(cellFrame.text, 'normal');
				end

				if table.selectionEnabled then
					if table.selected == rowIndex then
						table:SetHighLightColor(rowFrame, table.stdUi.config.highlight.color);
					else
						table:SetHighLightColor(rowFrame, nil);
					end
				end
			else
				cellFrame.text:SetText('');
			end
		end,

		Refresh = function(self)
			local scrollFrame = self.scrollFrame;
			self.stdUi.FauxScrollFrameMethods.Update(scrollFrame, #self.filtered, self.numberOfRows, self.rowHeight);

			local o = self.stdUi.FauxScrollFrameMethods.GetOffset(scrollFrame);
			self.offset = o;

			for i = 1, self.numberOfRows do
				local row = i + o;

				if self.rows then
					local rowFrame = self.rows[i];

					local rowIndex = self.filtered[row];
					local rowData = self:GetRow(rowIndex);
					local shouldShow = true;

					for col = 1, #self.columns do
						local cellFrame = rowFrame.columns[col];
						local columnData = self.columns[col];
						local fnDoCellUpdate = self.DoCellUpdate;
						local value;

						if rowData then
							value = rowData[columnData.index];

							self.rows[i]:Show();

							if rowData.doCellUpdate then
								fnDoCellUpdate = rowData.doCellUpdate;
							elseif columnData.doCellUpdate then
								fnDoCellUpdate = columnData.doCellUpdate;
							end
						else
							self.rows[i]:Hide();
							shouldShow = false;
						end

						fnDoCellUpdate(self, shouldShow, rowFrame, cellFrame, value, columnData, rowData, rowIndex);
					end
				end
			end
		end,

		-------------------------------------------------------------
		--- Private Methods
		-------------------------------------------------------------

		UpdateSortArrows = function(self, sortBy)
			if not self.head then
				return ;
			end

			for i = 1, #self.columns do
				local col = self.head.columns[i];
				if col then
					if i == sortBy then
						local column = self.columns[sortBy];
						local direction = column.sort or column.defaultSort or 'asc';
						if direction == 'asc' then
							col.arrow:SetTexCoord(0, 0.5625, 0, 1);
						else
							col.arrow:SetTexCoord(0, 0.5625, 1, 0);
						end

						col.arrow:Show();
					else
						col.arrow:Hide();
					end
				end
			end
		end,

		FireCellEvent = function(self, event, handler, ...)
			if not handler(self, ...) then
				if self.cellEvents[event] then
					self.cellEvents[event](self, ...);
				end
			end
		end,

		FireHeaderEvent = function(self, event, handler, ...)
			if not handler(self, ...) then
				if self.headerEvents[event] then
					self.headerEvents[event](self, ...);
				end
			end
		end,

		--- Set the event handlers for various ui events for each cell.
		--- @usage st:RegisterEvents(events, true)
		RegisterEvents = function(self, cellEvents, headerEvents, removeOldEvents)
			local table = self; -- save for closure later

			if cellEvents then
				-- Register events for each cell
				for i, rowFrame in ipairs(self.rows) do
					for j, cell in ipairs(rowFrame.columns) do

						local columnData = self.columns[j];

						-- unregister old events.
						if removeOldEvents and self.cellEvents then
							for event, handler in pairs(self.cellEvents) do
								cell:SetScript(event, nil);
							end
						end

						-- register new ones.
						for event, handler in pairs(cellEvents) do
							cell:SetScript(event, function(cellFrame, ...)
								local rowIndex = table.filtered[i + table.offset];
								local rowData = table:GetRow(rowIndex);
								table:FireCellEvent(event, handler, cellFrame, rowFrame, rowData, columnData,
										rowIndex, ...);
							end);
						end

						-- override a column based events
						if columnData.events then
							for event, handler in pairs(self.columns[j].events) do
								cell:SetScript(event, function(cellFrame, ...)
									if table.offset then
										local rowIndex = table.filtered[i + table.offset];
										local rowData = table:GetRow(rowIndex);
										table:FireCellEvent(event, handler, cellFrame, rowFrame, rowData, columnData,
												rowIndex, ...);
									end
								end);
							end
						end
					end
				end
			end

			if headerEvents then
				-- Register events on column headers
				for columnIndex, columnFrame in ipairs(self.head.columns) do
					-- unregister old events.
					if removeOldEvents and self.headerEvents then
						for event, handler in pairs(self.headerEvents) do
							columnFrame:SetScript(event, nil);
						end
					end

					-- register new ones.
					for event, handler in pairs(headerEvents) do
						columnFrame:SetScript(event, function(cellFrame, ...)
							table:FireHeaderEvent(event, handler, columnFrame, self.head, columnIndex, ...);
						end);
					end
				end
			end
		end,
	};

	local cellEvents = {
		OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)
			table:SetHighLightColor(rowFrame, table.stdUi.config.highlight.color);
			return true;
		end,

		OnLeave = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)
			if rowIndex ~= table.selected or not table.selectionEnabled then
				table:SetHighLightColor(rowFrame, nil);
			end

			return true;
		end,

		OnClick = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)
			if button == 'LeftButton' then
				if table:GetSelection() == rowIndex then
					table:ClearSelection();
				else
					table:SetSelection(rowIndex);
				end

				return true;
			end
		end,
	};

	local headerEvents = {
		OnClick = function(table, columnFrame, columnHeadFrame, columnIndex, button, ...)
			if button == 'LeftButton' then

				local columns = table.columns;
				local column = columns[columnIndex];
				
				-- clear sort for other columns
				for i, columnFrame in ipairs(columnHeadFrame.columns) do
					if i ~= columnIndex then
						columns[i].sort = nil;
					end
				end

				local sortOrder = 'asc';

				if not column.sort and column.defaultSort then
					-- sort by columns default sort first;
					sortOrder = column.defaultSort;
				elseif column.sort and column.sort:lower() == 'asc' then
					sortOrder = 'dsc';
				end

				column.sort = sortOrder;
				table:SortData();

				return true;
			end
		end
	};

	function StdUi:ScrollTable(parent, columns, numRows, rowHeight)
		local scrollTable, scrollFrame, scrollChild, scrollBar = self:FauxScrollFrame(parent, 100, 100, rowHeight or 15);

		scrollTable.stdUi = self;
		scrollTable.numberOfRows = numRows or 12;
		scrollTable.rowHeight = rowHeight or 15;
		scrollTable.columns = columns;
		scrollTable.data = {};
		scrollTable.cellEvents = cellEvents;
		scrollTable.headerEvents = headerEvents;

		-- Add all methods
		for methodName, method in pairs(methods) do
			scrollTable[methodName] = method;
		end

		scrollTable.scrollFrame = scrollFrame;

		scrollFrame:SetScript('OnVerticalScroll', function(self, offset)
			-- LS: putting st:Refresh() in a function call passes the st as the 1st arg which lets you
			-- reference the st if you decide to hook the refresh
			scrollTable.stdUi.FauxScrollFrameMethods.OnVerticalScroll(self, offset, scrollTable.rowHeight, function()
				scrollTable:Refresh();
			end);
		end);

		scrollTable:SortData();
		scrollTable:SetColumns(scrollTable.columns);
		scrollTable:UpdateSortArrows();
		scrollTable:RegisterEvents(scrollTable.cellEvents, scrollTable.headerEvents);
		-- no need to assign it once again and override all column events

		return scrollTable;
	end

	StdUi:RegisterModule(module, version);
end 

init_ScrollTable()


--------------------------------------
-- Widgets: Slider.lua
--------------------------------------
local function init_Slider()
	local module, version = 'Slider', 4;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	local function roundPrecision(value, precision)
		local multiplier = 10 ^ (precision or 0);
		return math.floor(value * multiplier + 0.5) / multiplier;
	end

	function StdUi:SliderButton(parent, width, height, direction)
		local button = self:Button(parent, width, height);

		local texture = self:ArrowTexture(button, direction);
		texture:SetPoint('CENTER');

		local textureDisabled = self:ArrowTexture(button, direction);
		textureDisabled:SetPoint('CENTER');
		textureDisabled:SetDesaturated(0);

		button:SetNormalTexture(texture);
		button:SetDisabledTexture(textureDisabled);

		return button;
	end

	--- This is only useful for scrollBars not created using StdUi
	function StdUi:StyleScrollBar(scrollBar)
		local buttonUp, buttonDown = scrollBar:GetChildren();

		scrollBar.background = StdUi:Panel(scrollBar);
		scrollBar.background:SetFrameLevel(scrollBar:GetFrameLevel() - 1);
		scrollBar.background:SetWidth(scrollBar:GetWidth());
		self:GlueAcross(scrollBar.background, scrollBar, 0, 1, 0, -1);

		self:StripTextures(buttonUp);
		self:StripTextures(buttonDown);

		self:ApplyBackdrop(buttonUp, 'button');
		self:ApplyBackdrop(buttonDown, 'button');

		buttonUp:SetWidth(scrollBar:GetWidth());
		buttonDown:SetWidth(scrollBar:GetWidth());

		local upTex = self:ArrowTexture(buttonUp, 'UP');
		upTex:SetPoint('CENTER');

		local upTexDisabled = self:ArrowTexture(buttonUp, 'UP');
		upTexDisabled:SetPoint('CENTER');
		upTexDisabled:SetDesaturated(0);

		buttonUp:SetNormalTexture(upTex);
		buttonUp:SetDisabledTexture(upTexDisabled);

		local downTex = self:ArrowTexture(buttonDown, 'DOWN');
		downTex:SetPoint('CENTER');

		local downTexDisabled = self:ArrowTexture(buttonDown, 'DOWN');
		downTexDisabled:SetPoint('CENTER');
		downTexDisabled:SetDesaturated(0);

		buttonDown:SetNormalTexture(downTex);
		buttonDown:SetDisabledTexture(downTexDisabled);

		local thumbSize = scrollBar:GetWidth();
		scrollBar:GetThumbTexture():SetWidth(thumbSize);

		self:StripTextures(scrollBar);

		scrollBar.thumb = self:Panel(scrollBar);
		scrollBar.thumb:SetAllPoints(scrollBar:GetThumbTexture());
		self:ApplyBackdrop(scrollBar.thumb, 'button');
	end

	function StdUi:Slider(parent, width, height, value, vertical, min, max)
		local slider = CreateFrame('Slider', nil, parent);
		self:InitWidget(slider);
		self:ApplyBackdrop(slider, 'panel');
		self:SetObjSize(slider, width, height);

		slider.vertical = vertical;
		slider.precision = 1;

		local thumbWidth = vertical and width or 20;
		local thumbHeight = vertical and 20 or height;

		slider.ThumbTexture = self:Texture(slider, thumbWidth, thumbHeight, self.config.backdrop.texture);
		slider.ThumbTexture:SetVertexColor(
			self.config.backdrop.slider.r,
			self.config.backdrop.slider.g,
			self.config.backdrop.slider.b,
			self.config.backdrop.slider.a
		);
		slider:SetThumbTexture(slider.ThumbTexture);

		slider.thumb = self:Frame(slider);
		slider.thumb:SetAllPoints(slider:GetThumbTexture());
		self:ApplyBackdrop(slider.thumb, 'button');

		if vertical then
			slider:SetOrientation('VERTICAL');
			slider.ThumbTexture:SetPoint('LEFT');
			slider.ThumbTexture:SetPoint('RIGHT');
		else
			slider:SetOrientation('HORIZONTAL');
			slider.ThumbTexture:SetPoint('TOP');
			slider.ThumbTexture:SetPoint('BOTTOM');
		end

		function slider:SetPrecision(numberOfDecimals)
			self.precision = numberOfDecimals;
		end

		function slider:GetPrecision()
			return self.precision;
		end

		slider.OriginalGetValue = slider.GetValue;

		function slider:GetValue()
			local minimum, maximum = self:GetMinMaxValues();
			return Clamp(roundPrecision(self:OriginalGetValue(), self.precision), minimum, maximum);
		end

		slider:SetMinMaxValues(min or 0, max or 100);
		slider:SetValue(value or min or 0);

		slider:HookScript('OnValueChanged', function(s, value, ...)
			if s.lock then return; end
			s.lock = true;
			value = slider:GetValue();

			if s.OnValueChanged then
				s.OnValueChanged(s, value, ...);
			end

			s.lock = false;
		end);

		return slider;
	end

	function StdUi:SliderWithBox(parent, width, height, value, min, max)
		local widget = CreateFrame('Frame', nil, parent);
		self:SetObjSize(widget, width, height);

		widget.slider = self:Slider(widget, 100, 12, value, false);
		widget.editBox = self:NumericBox(widget, 80, 16, value);
		widget.value = value;
		widget.editBox:SetNumeric(false);
		widget.leftLabel = self:Label(widget, '');
		widget.rightLabel = self:Label(widget, '');

		widget.slider.widget = widget;
		widget.editBox.widget = widget;

		function widget:SetValue(value)
			self.lock = true;
			self.slider:SetValue(value);
			value = self.slider:GetValue();
			self.editBox:SetValue(value);
			self.value = value;
			self.lock = false;

			if self.OnValueChanged then
				self.OnValueChanged(self, value);
			end
		end

		function widget:GetValue()
			return self.value;
		end

		function widget:SetValueStep(step)
			self.slider:SetValueStep(step);
		end

		function widget:SetPrecision(numberOfDecimals)
			self.slider.precision = numberOfDecimals;
		end

		function widget:GetPrecision()
			return self.slider.precision;
		end

		function widget:SetMinMaxValues(min, max)
			widget.min = min;
			widget.max = max;

			widget.editBox:SetMinMaxValue(min, max);
			widget.slider:SetMinMaxValues(min, max);
			widget.leftLabel:SetText(min);
			widget.rightLabel:SetText(max);
		end

		if min and max then
			widget:SetMinMaxValues(min, max);
		end

		widget.slider.OnValueChanged = function(s, val)
			if s.widget.lock then return end;

			s.widget:SetValue(val);
		end;

		widget.editBox.OnValueChanged = function(e, val)
			if e.widget.lock then return end;

			e.widget:SetValue(val);
		end;

		widget.slider:SetPoint('TOPLEFT', widget, 'TOPLEFT', 0, 0);
		widget.slider:SetPoint('TOPRIGHT', widget, 'TOPRIGHT', 0, 0);
		self:GlueBelow(widget.editBox, widget.slider, 0, -5, 'CENTER');
		widget.leftLabel:SetPoint('TOPLEFT', widget.slider, 'BOTTOMLEFT', 0, 0);
		widget.rightLabel:SetPoint('TOPRIGHT', widget.slider, 'BOTTOMRIGHT', 0, 0);

		return widget;
	end

	function StdUi:ScrollBar(parent, width, height, horizontal)

		local panel = self:Panel(parent, width, height);
		local scrollBar = self:Slider(parent, width, height, 0, not horizontal);

		scrollBar.ScrollDownButton = self:SliderButton(parent, width, 16, 'DOWN');
		scrollBar.ScrollUpButton = self:SliderButton(parent, width, 16, 'UP');
		scrollBar.panel = panel;

		scrollBar.ScrollUpButton.scrollBar = scrollBar;
		scrollBar.ScrollDownButton.scrollBar = scrollBar;

		if horizontal then
			--@TODO do this
			--scrollBar.ScrollUpButton:SetPoint('TOPLEFT', panel, 'TOPLEFT', 0, 0);
			--scrollBar.ScrollUpButton:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', 0, 0);
			--
			--scrollBar.ScrollDownButton:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', 0, 0);
			--scrollBar.ScrollDownButton:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', 0, 0);
			--
			--scrollBar:SetPoint('TOPLEFT', scrollBar.ScrollUpButton, 'TOPLEFT', 0, 1);
			--scrollBar:SetPoint('TOPRIGHT', scrollBar.ScrollUpButton, 'TOPRIGHT', 0, 1);
			--scrollBar:SetPoint('BOTTOMLEFT', scrollBar.ScrollDownButton, 'BOTTOMLEFT', 0, -1);
			--scrollBar:SetPoint('BOTTOMRIGHT', scrollBar.ScrollDownButton, 'BOTTOMRIGHT', 0, -1);
		else
			scrollBar.ScrollUpButton:SetPoint('TOPLEFT', panel, 'TOPLEFT', 0, 0);
			scrollBar.ScrollUpButton:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', 0, 0);

			scrollBar.ScrollDownButton:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', 0, 0);
			scrollBar.ScrollDownButton:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', 0, 0);

			scrollBar:SetPoint('TOPLEFT', scrollBar.ScrollUpButton, 'BOTTOMLEFT', 0, 1);
			scrollBar:SetPoint('TOPRIGHT', scrollBar.ScrollUpButton, 'BOTTOMRIGHT', 0, 1);
			scrollBar:SetPoint('BOTTOMLEFT', scrollBar.ScrollDownButton, 'TOPLEFT', 0, -1);
			scrollBar:SetPoint('BOTTOMRIGHT', scrollBar.ScrollDownButton, 'TOPRIGHT', 0, -1);
		end

		return scrollBar, panel;
	end

	StdUi:RegisterModule(module, version);
end 

init_Slider()


--------------------------------------
-- Widgets: Spell.lua
--------------------------------------
local function init_Spell()
	local module, version = 'Spell', 1;
	if not StdUi:UpgradeNeeded(module, version) then
		return
	end ;

	function StdUi:SpellBox(parent, width, height, iconSize, spellValidator)
		iconSize = iconSize or 16;
		local editBox = self:EditBox(parent, width, height, '', spellValidator or self.Util.spellValidator);
		editBox:SetTextInsets(iconSize + 7, 3, 3, 3);

		local iconFrame = self:Panel(editBox, iconSize, iconSize);
		self:GlueLeft(iconFrame, editBox, 2, 0, true);

		local icon = self:Texture(iconFrame, iconSize, iconSize, 134400);
		icon:SetAllPoints();

		editBox.icon = icon;

		iconFrame:SetScript('OnEnter', function()
			if editBox.value then
				GameTooltip:SetOwner(editBox);
				GameTooltip:SetSpellByID(editBox.value)
				GameTooltip:Show();
			end
		end)

		iconFrame:SetScript('OnLeave', function()
			if editBox.value then
				GameTooltip:Hide();
			end
		end)

		return editBox;
	end

	function StdUi:SpellInfo(parent, width, height, iconSize)
		iconSize = iconSize or 16;
		local frame = self:Panel(parent, width, height);

		local iconFrame = self:Panel(frame, iconSize, iconSize);
		self:GlueLeft(iconFrame, frame, 2, 0, true);

		local icon = self:Texture(iconFrame, iconSize, iconSize);
		icon:SetAllPoints();

		local btn = self:SquareButton(frame, iconSize, iconSize, 'DELETE');
		StdUi:GlueRight(btn, frame, -3, 0, true);

		local text = self:Label(frame);
		text:SetPoint('LEFT', icon, 'RIGHT', 3, 0);
		text:SetPoint('RIGHT', btn, 'RIGHT', -3, 0);

		frame.removeBtn = btn;
		frame.icon = icon;
		frame.text = text;

		btn.parent = frame;

		iconFrame:SetScript('OnEnter', function()
			GameTooltip:SetOwner(frame);
			GameTooltip:SetSpellByID(frame.spellId);
			GameTooltip:Show();
		end)

		iconFrame:SetScript('OnLeave', function()
			GameTooltip:Hide();
		end)

		function frame:SetSpell(nameOrId)
			local name, _, i, _, _, _, spellId = GetSpellInfo(nameOrId);
			self.spellId = spellId;
			self.spellName = name;

			self.icon:SetTexture(i);
			self.text:SetText(name);
		end

		return frame;
	end;

	function StdUi:SpellCheckbox(parent, width, height, iconSize)
		iconSize = iconSize or 16;
		local checkbox = self:Checkbox(parent, '', width, height);
		checkbox.spellId = nil;
		checkbox.spellName = '';

		local iconFrame = self:Panel(checkbox, iconSize, iconSize);
		iconFrame:SetPoint('LEFT', checkbox.target, 'RIGHT', 5, 0);

		local icon = self:Texture(iconFrame, iconSize, iconSize);
		icon:SetAllPoints();

		checkbox.icon = icon;

		checkbox.text:SetPoint('LEFT', iconFrame, 'RIGHT', 5, 0);

		checkbox:SetScript('OnEnter', function()
			if checkbox.spellId then
				GameTooltip:SetOwner(checkbox);
				GameTooltip:SetSpellByID(checkbox.spellId);
				GameTooltip:Show();
			end
		end)

		checkbox:SetScript('OnLeave', function()
			if checkbox.spellId then
				GameTooltip:Hide();
			end
		end)

		function checkbox:SetSpell(nameOrId)
			local name, _, i, _, _, _, spellId = GetSpellInfo(nameOrId);
			self.spellId = spellId;
			self.spellName = name;

			self.icon:SetTexture(i);
			self.text:SetText(name);
		end

		return checkbox;
	end;

	StdUi:RegisterModule(module, version);
end 

init_Spell()


--------------------------------------
-- Widgets: Tab.lua
--------------------------------------
local function init_Tab()
	local module, version = 'Tab', 3;
	if not StdUi:UpgradeNeeded(module, version) then
		return
	end ;

	---
	---local t = {
	---    {
	---        name = 'firstTab',
	---        title = 'First',
	---    },
	---    {
	---        name = 'secondTab',
	---        title = 'Second',
	---    },
	---    {
	---        name = 'thirdTab',
	---        title = 'Third'
	---    }
	---}
	function StdUi:TabPanel(parent, width, height, tabs, vertical, buttonWidth, buttonHeight)
		local this = self;
		vertical = vertical or false;
		buttonHeight = buttonHeight or 20;
		buttonWidth = buttonWidth or 160;

		local tabFrame = self:Frame(parent, width, height);
		tabFrame.vertical = vertical;

		tabFrame.tabs = tabs;

		tabFrame.buttonContainer = self:Frame(tabFrame);
		tabFrame.container = self:Panel(tabFrame);

		if vertical then
			tabFrame.buttonContainer:SetPoint('TOPLEFT', tabFrame, 'TOPLEFT', 0, 0);
			tabFrame.buttonContainer:SetPoint('BOTTOMLEFT', tabFrame, 'BOTTOMLEFT', 0, 0);
			tabFrame.buttonContainer:SetWidth(buttonWidth);

			tabFrame.container:SetPoint('TOPLEFT', tabFrame.buttonContainer, 'TOPRIGHT', 5, 0);
			tabFrame.container:SetPoint('BOTTOMLEFT', tabFrame.buttonContainer, 'BOTTOMRIGHT', 5, 0);
			tabFrame.container:SetPoint('TOPRIGHT', tabFrame, 'TOPRIGHT', 0, 0);
			tabFrame.container:SetPoint('BOTTOMRIGHT', tabFrame, 'BOTTOMRIGHT', 0, 0);
		else
			tabFrame.buttonContainer:SetPoint('TOPLEFT', tabFrame, 'TOPLEFT', 0, 0);
			tabFrame.buttonContainer:SetPoint('TOPRIGHT', tabFrame, 'TOPRIGHT', 0, 0);
			tabFrame.buttonContainer:SetHeight(buttonHeight);

			tabFrame.container:SetPoint('TOPLEFT', tabFrame.buttonContainer, 'BOTTOMLEFT', 0, -5);
			tabFrame.container:SetPoint('TOPRIGHT', tabFrame.buttonContainer, 'BOTTOMRIGHT', 0, -5);
			tabFrame.container:SetPoint('BOTTOMLEFT', tabFrame, 'BOTTOMLEFT', 0, 0);
			tabFrame.container:SetPoint('BOTTOMRIGHT', tabFrame, 'BOTTOMRIGHT', 0, 0);
		end

		function tabFrame:EnumerateTabs(callback)
			for i = 1, #self.tabs do
				local tab = self.tabs[i];
				if callback(tab, self) then
					break ;
				end
			end
		end

		function tabFrame:HideAllFrames()
			self:EnumerateTabs(function(tab)
				if tab.frame then
					tab.frame:Hide();
				end
			end);
		end

		function tabFrame:DrawButtons()
			self:EnumerateTabs(function(tab)
				if tab.button then
					tab.button:Hide();
				end
			end);

			local prevBtn;
			self:EnumerateTabs(function(tab, parentTabFrame)
				local btn = tab.button;
				local btnContainer = parentTabFrame.buttonContainer;

				if not btn then
					btn = this:Button(btnContainer, nil, buttonHeight);
					tab.button = btn;
					btn.tabFrame = parentTabFrame;

					btn:SetScript('OnClick', function(bt)
						bt.tabFrame:SelectTab(bt.tab.name);
					end);
				end

				btn.tab = tab;
				btn:SetText(tab.title);
				btn:ClearAllPoints();

				if parentTabFrame.vertical then
					btn:SetWidth(buttonWidth);
				else
					this:ButtonAutoWidth(btn);
				end

				if parentTabFrame.vertical then
					if not prevBtn then
						this:GlueTop(btn, btnContainer, 0, 0, 'CENTER');
					else
						this:GlueBelow(btn, prevBtn, 0, -1);
					end
				else
					if not prevBtn then
						this:GlueTop(btn, btnContainer, 0, 0, 'LEFT');
					else
						this:GlueRight(btn, prevBtn, 5, 0);
					end
				end

				btn:Show();
				prevBtn = btn;
			end);
		end

		function tabFrame:DrawFrames()
			self:EnumerateTabs(function(tab)
				if not tab.frame then
					tab.frame = this:Frame(self.container);
				end

				tab.frame:ClearAllPoints();
				tab.frame:SetAllPoints();
			end);
		end

		function tabFrame:Update(newTabs)
			if newTabs then
				self.tabs = newTabs;
			end
			self:DrawButtons();
			self:DrawFrames();
		end

		function tabFrame:GetTabByName(name)
			local foundTab;

			self:EnumerateTabs(function(tab)
				if tab.name == name then
					foundTab = tab;
					return true;
				end
			end);
			return foundTab;
		end

		function tabFrame:SelectTab(name)
			self.selected = name;
			if self.selectedTab then
				self.selectedTab.button:Enable();
			end

			self:HideAllFrames();
			local foundTab = self:GetTabByName(name);

			if foundTab.name == name and foundTab.frame then
				foundTab.button:Disable();
				foundTab.frame:Show();
				tabFrame.selectedTab = foundTab;
				return true;
			end
		end

		function tabFrame:GetSelectedTab()
			return self.selectedTab;
		end

		tabFrame:Update();
		if #tabFrame.tabs > 0 then
			tabFrame:SelectTab(tabFrame.tabs[1].name);
		end

		return tabFrame;
	end

	StdUi:RegisterModule(module, version);
end 

init_Tab()


--------------------------------------
-- Widgets: Table.lua
--------------------------------------
local function init_Table()
	local module, version = 'Table', 1;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	--- Draws table in a panel according to data, example:
	--- local columns = {
	---		{header = 'Name', index = 'name', width = 20, align = 'RIGHT'},
	---		{header = 'Price', index = 'price', width = 60},
	--- };
	--- local data {
	---		{name = 'Item one', price = 12.22},
	---		{name = 'Item two', price = 11.11},
	---		{name = 'Item three', price = 10.12},
	--- }
	---
	function StdUi:Table(parent, width, height, rowHeight, columns, data)
		local this = self;
		local panel = self:Panel(parent, width, height);
		panel.rowHeight = rowHeight;

		function panel:SetColumns(columns)
			panel.columns = columns;
		end

		function panel:SetData(data)
			self.tableData = data;
		end

		function panel:AddRow(row)
			if not self.tableData then
				self.tableData = {};
			end

			tinsert(self.tableData, row);
		end

		function panel:DrawHeaders()
			if not self.headers then
				self.headers = {};
			end

			local marginLeft = 0;
			for i = 1, #self.columns do
				local col = self.columns[i];

				if col.header and strlen(col.header) > 0 then
					if not self.headers[i] then
						self.headers[i] = {
							text = this:FontString(self, ''),
						};
					end

					local column = self.headers[i];

					column.text:SetText(col.header);
					column.text:SetWidth(col.width);
					column.text:SetHeight(rowHeight);
					column.text:ClearAllPoints();
					if col.align then
						column.text:SetJustifyH(col.align);
					end

					this:GlueTop(column.text, self, marginLeft, 0, 'LEFT');
					marginLeft = marginLeft + col.width;

					column.index = col.index
					column.width = col.width
				end
			end
		end

		function panel:DrawData()
			if not self.rows then
				self.rows = {};
			end

			local marginTop = -rowHeight;
			for y = 1, #self.tableData do
				local row = self.tableData[y];

				local marginLeft = 0;
				for x = 1, #self.columns do
					local col = self.columns[x];

					if not self.rows[y] then
						self.rows[y] = {};
					end

					if not self.rows[y][x] then
						self.rows[y][x] = {
							text = this:FontString(self, '');
						};
					end

					local cell = self.rows[y][x];

					cell.text:SetText(row[col.index]);
					cell.text:SetWidth(col.width);
					cell.text:SetHeight(rowHeight);
					cell.text:ClearAllPoints();
					if col.align then
						cell.text:SetJustifyH(col.align);
					end

					this:GlueTop(cell.text, self, marginLeft, marginTop, 'LEFT');
					marginLeft = marginLeft + col.width;
				end

				marginTop = marginTop - rowHeight;
			end
		end

		function panel:DrawTable()
			self:DrawHeaders();
			self:DrawData();
		end

		panel:SetColumns(columns);
		panel:SetData(data);
		panel:DrawTable();

		return panel;
	end

	StdUi:RegisterModule(module, version);
end 

init_Table()


--------------------------------------
-- Widgets: Tooltip.lua
--------------------------------------
local function init_Tooltip()
	local module, version = 'Tooltip', 1;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	StdUi.tooltips = {}
	StdUi.frameTooltips = {}

	--- Standard blizzard tooltip
	---@return GameTooltip
	function StdUi:Tooltip(owner, text, tooltipName, anchor, automatic)
		--- @type GameTooltip
		local tip;
		local this = self;

		if tooltipName and self.tooltips[tooltipName] then
			tip = self.tooltips[tooltipName];
		else
			tip = CreateFrame('GameTooltip', tooltipName, UIParent, 'GameTooltipTemplate');

			self:ApplyBackdrop(tip, 'panel');
		end

		tip.owner = owner;
		tip.anchor = anchor;

		if automatic then
			owner:HookScript('OnEnter', function (self)
				tip:SetOwner(owner or UIParent, anchor or 'ANCHOR_NONE');

				if type(text) == 'string' then
					tip:SetText(text,
						this.config.font.color.r,
						this.config.font.color.g,
						this.config.font.color.b,
						this.config.font.color.a
					);
				elseif type(text) == 'function' then
					text(tip);
				end

				tip:Show();
				tip:ClearAllPoints();
				this:GlueOpposite(tip, tip.owner, 0, 0, tip.anchor);
			end);
			owner:HookScript('OnLeave', function ()
				tip:Hide();
			end);
		end

		return tip;
	end

	function StdUi:FrameTooltip(owner, text, tooltipName, anchor, automatic)
		--- @type GameTooltip
		local tip;
		local this = self;

		if tooltipName and self.frameTooltips[tooltipName] then
			tip = self.frameTooltips[tooltipName];
		else
			tip = self:Panel(UIParent, 10, 10);
			tip:SetFrameStrata('TOOLTIP');
			self:ApplyBackdrop(tip, 'panel');

			local padding = self.config.tooltip.padding;

			tip.text = self:FontString(tip, '');
			self:GlueTop(tip.text, tip, padding, -padding, 'LEFT');

			function tip:SetText(text, r, g, b)
				if r and g and b then
					text = this.Util.WrapTextInColor(text, r, g, b, 1);
				end
				tip.text:SetText(text);

				tip:RecalculateSize();
			end

			function tip:GetText()
				return tip.text:GetText();
			end

			function tip:AddLine(text, r, g, b)
				local txt = self:GetText();
				if not txt then
					txt = '';
				else
					txt = txt .. '\n'
				end
				if r and g and b then
					text = this.Util.WrapTextInColor(text, r, g, b, 1);
				end
				self:SetText(txt .. text);
			end

			function tip:RecalculateSize()
				tip:SetSize(tip.text:GetWidth() + padding * 2, tip.text:GetHeight() + padding * 2);
			end

			hooksecurefunc(tip, 'Show', function(self)
				self:RecalculateSize();
				self:ClearAllPoints();
				this:GlueOpposite(self, self.owner, 0, 0, self.anchor);
			end);
		end

		tip.owner = owner;
		tip.anchor = anchor;

		if type(text) == 'string' then
			tip:SetText(text);
		elseif type(text) == 'function' then
			text(tip);
		end

		if automatic then
			owner:HookScript('OnEnter', function ()
				tip:Show();
			end);
			owner:HookScript('OnLeave', function ()
				tip:Hide();
			end);
		end

		return tip;
	end

	StdUi:RegisterModule(module, version);
end 

init_Tooltip()


--------------------------------------
-- Widgets: Window.lua
--------------------------------------
local function init_Window()
	local module, version = 'Window', 4;
	if not StdUi:UpgradeNeeded(module, version) then return end;

	--- @return Frame
	function StdUi:Window(parent, title, width, height)
		parent = parent or UIParent;
		local frame = self:PanelWithTitle(parent, width, height, title);
		frame:SetClampedToScreen(true);
		frame.titlePanel.isWidget = false;
		self:MakeDraggable(frame); -- , frame.titlePanel

		local closeBtn = self:Button(frame, 16, 16, 'X');
		closeBtn.text:SetFontSize(12);
		closeBtn.isWidget = false;
		self:GlueTop(closeBtn, frame, -10, -10, 'RIGHT');

		closeBtn:SetScript('OnClick', function(self)
			self:GetParent():Hide();
		end);

		frame.closeBtn = closeBtn;

		function frame:SetWindowTitle(title)
			self.titlePanel.label:SetText(title);
		end

		return frame;
	end

	-- Reusing dialogs
	StdUi.dialogs = {};
	--- @return Frame
	function StdUi:Dialog(title, message, dialogId)
		local window;
		if dialogId and self.dialogs[dialogId] then
			window = self.dialogs[dialogId];
		else
			window = self:Window(nil, title, self.config.dialog.width, self.config.dialog.height);
			window:SetPoint('CENTER');
			window:SetFrameStrata('DIALOG');
		end

		if window.messageLabel then
			window.messageLabel:SetText(message);
		else
			window.messageLabel = self:Label(window, message);
			window.messageLabel:SetJustifyH('MIDDLE');
			self:GlueAcross(window.messageLabel, window, 5, -10, -5, 5);
		end

		window:Show();

		if dialogId then
			self.dialogs[dialogId] = window;
		end
		return window;
	end

	--- Dialog with additional buttons, buttons can be like this
	--- local btn = {
	---		ok = {
	---			text = 'OK',
	---			onClick = function() end
	---		},
	---		cancel = {
	---			text = 'Cancel',
	---			onClick = function() end
	---		}
	--- }
	--- @return Frame
	function StdUi:Confirm(title, message, buttons, dialogId)
		local window = self:Dialog(title, message, dialogId);

		if buttons and not window.buttons then
			window.buttons = {};

			local btnCount = self.Util.tableCount(buttons);

			local btnMargin = self.config.dialog.button.margin;
			local btnWidth = self.config.dialog.button.width;
			local btnHeight = self.config.dialog.button.height;

			local totalWidth = btnCount * btnWidth + (btnCount - 1) * btnMargin;
			local leftMargin = math.floor((self.config.dialog.width - totalWidth) / 2);

			local i = 0;
			for k, btnDefinition in pairs(buttons) do
				local btn = self:Button(window, btnWidth, btnHeight, btnDefinition.text);
				btn.window = window;

				self:GlueBottom(btn, window, leftMargin + (i * (btnWidth + btnMargin)), 10, 'LEFT');

				if btnDefinition.onClick then
					btn:SetScript('OnClick', btnDefinition.onClick);
				end

				window.buttons[k] = btn;
				i = i + 1;
			end

			window.messageLabel:ClearAllPoints();
			self:GlueAcross(window.messageLabel, window, 5, -10, -5, 5 + btnHeight + 5);
		end

		return window;
	end

	StdUi:RegisterModule(module, version);
end 

init_Window()