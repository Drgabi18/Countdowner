Events = {
--[[ [i] = {
["Name"] = "",
["Date"] = Year-Month-Day,
["Time"] = Hour:Minute:Seconds
}
]]
}

-- we doing OOP now
function Events.New(Name, Date, Time)
	local Event = {}
	
	Event.Name = Name
	Event.Date = Date
	Event.Time = Time
	
	table.insert(Events, Event)
end

function Events.Remove(index)
	table.remove(Events, index)
end

function Events.GenerateArrayFromFile()
	for i = 1, SKIN:GetVariable("Events", 1) do
		local Name = SKIN:GetVariable("Name"..i, "New Event")
		local Date = SKIN:GetVariable("Date"..i, "2030-04-20")
		local Time = SKIN:GetVariable("Time"..i, "04:20:00")
		
		-- if one of the needed values is missing, error out
		if (Name == '') or (Date == '') or (Time == '') then assert("Invalid Name/Date/Time, make sure they're all filled correctly.") end
		
		Events.New(Name, Date, Time)
	end
end

function Events.RegenerateArrayToFile()
	-- BUG: While this shifts the elements around and saves them to the file, it dose not remove old ones out, I don't know how to
	for i, v in ipairs(Events) do
		SKIN:Bang("!WriteKeyValue", "Variables", "Name"..i, v.Name, "Events.inc")
		SKIN:Bang("!WriteKeyValue", "Variables", "Date"..i, v.Date, "Events.inc")
		SKIN:Bang("!WriteKeyValue", "Variables", "Time"..i, v.Time, "Events.inc")
	end
end

-- this is the file that we write all the sections to and then write to file
local Events2Sections = {}

function GenerateMetersFile()
	-- idk how to make an assert if file can't be opened
	local FILE = io.open(SKIN:MakePathAbsolute(SELF:GetOption("GeneratedFile")), "w")
	
	-- we start the necesary steps for writing to the file, a big ass warning
	table.insert(Events2Sections,
	[[; ==============================
	; THIS FILE IS GENERATED AUTOMATICALLY THROUGH LUA
	; ANY CHANGES YOU WOULD MAKE WILL GET REMOVED
	; ONCE THE FILE REGENERATES
	; ==============================
	]]
	)
	
	-- is doing `string.format("str", i, i, i, i, i, i)` not an efficient way of doing this? yes, yes it isn't
	for i, v in ipairs(Events) do
		table.insert(Events2Sections,
			string.format(
			[[
			[TimestampMeasure%s]
			Measure=Time
			Timestamp=#Date%s#T#Time%s#Z
			TimeStampFormat=%%Y-%%m-%%dT%%H:%%M:%%SZ
			DynamicVariables=1
			]],
			i, i, i)
		)
					
		table.insert(Events2Sections,
			string.format(
			[[
			[UptimeMeasure%s]
			Measure=Uptime
			SecondsValue=([TimestampMeasure%s:Timestamp]-[CurrentTime:Timestamp])
			Format=#UptimeFormat#
			UpdateDivider=1
			DynamicVariables=1
			]],
			i, i)
		)
		
		table.insert(Events2Sections,
			string.format(
			[[
			[InputTextMeasure%s]
			Measure=Plugin
			Plugin=InputText
			H=(12*3*#Scale#)
			W=(100*2*#Scale#)
			FontSize=(12*#Scale#)
			SolidColor=#BackgroundFillSecondaryColor#
			Command1=[!SetVariable "Name%s" "$UserInput$"][!WriteKeyValue "Variables" "Name%s" "[#Name%s]" "Events.inc"][!UpdateMeterGroup "Updatable"][!Redraw]
			Command2=[!SetVariable "Date%s" "$UserInput$"][!WriteKeyValue "Variables" "Date%s" "[#Date%s]" "Events.inc"][!UpdateMeasure "TimestampMeasure%s"][!UpdateMeterGroup "Updatable"][!Redraw]
			Command3=[!SetVariable "Time%s" "$UserInput$"][!WriteKeyValue "Variables" "Time%s" "[#Time%s]" "Events.inc"][!UpdateMeasure "TimestampMeasure%s"][!UpdateMeterGroup "Updatable"][!Redraw]
			UpdateDivider=1
			]],
			i, i, i, i, i, i, i, i, i, i, i, i)
		)
		
		table.insert(Events2Sections,
			string.format(
			[[
			[ContainerMeterForList%s]
			Meter=Image
			W=(#ListWidth#*#Scale#)
			H=(#ListHeigt#*#Scale#)
			SolidColor=000000
			X=(12*#Scale#)
			Y=(12*#Scale#)R
			]],
			i)
		)
		
		-- instead of using a single shape meter for all of them, we create a shape meter individually cause i'm lazy
		table.insert(Events2Sections,
			string.format(
			[[
			[BackgroundMeter%s]
			Meter=Shape
			Container=ContainerMeterForList%s
			Shape=Rectangle 0,0,#ListWidth#,#ListHeigt#,4 | StrokeWidth 0 | Fill LinearGradient TheGradient | Scale #Scale#,#Scale#,0,0
			TheGradient=270 | #BackgroundFillSecondaryColor# ; -1.0 | #AccentColor# ; 10.0
			]],
			i, i)
		)
		
		table.insert(Events2Sections,
			string.format(
			[[
			[MeterEventTitle%s]
			Meter=String
			Container=ContainerMeterForList%s
			DynamicVariables=1
			Text=#Name%s#
			MeterStyle=NameStyle
			LeftMouseUpAction=[!CommandMeasure "InputTextMeasure%s" "ExecuteBatch 1"]
			]],
			i, i, i, i, i)
		)
		
		table.insert(Events2Sections,
			string.format(
			[[
			[MeterSubtitleDate%s]
			Meter=String
			Container=ContainerMeterForList%s
			DynamicVariables=1
			Text=#Date%s#
			MeterStyle=SubtitleStyle
			LeftMouseUpAction=[!CommandMeasure "InputTextMeasure%s" "ExecuteBatch 2"]
			]],
			i, i, i, i)
		)
		
		table.insert(Events2Sections,
			string.format(
			[[
			[MeterSubtitleTime%s]
			Meter=String
			Container=ContainerMeterForList%s
			DynamicVariables=1
			Text=#Time%s#
			MeterStyle=SubtitleStyle
			LeftMouseUpAction=[!CommandMeasure "InputTextMeasure%s" "ExecuteBatch 3"]
			]],
			i, i, i, i)
		)
		
		-- character variable because lua is utf-8 :(
		table.insert(Events2Sections,
			string.format(
			[[
			[MinusMeter%s]
			Meter=String
			Text=[\x2796]
			MeterStyle=SubtitleStyle
			FontColor=FF0000
			Group=Hideable
			Container=ContainerMeterForList%s
			X=(12*#Scale#)R
			ToolTipText=Remove the event
			LeftMouseUpAction=[!CommandMeasure "Everything" "Events.Remove(%s)"][!CommandMeasure "Everything" "Events.RegenerateArrayToFile()"][!SetVariable "Events" "([#Events]-1)"][!WriteKeyValue "Variables" "Events" "[#Events]" "Events.inc"][!WriteKeyValue "Everything" "ToRefresh" "1"][!Refresh]
			]],
			i, i, i)
		)
		
		table.insert(Events2Sections,
			string.format(
			[[
			[MeterCowntdownTime%s]
			Meter=String
			Container=ContainerMeterForList%s
			MeasureName=UptimeMeasure%s		
			MeterStyle=TimeUntillStyle
			X=[MeterEventTitle%s:X]
			Y=(50*#Scale#)
			UpdateDivider=1
			DynamicVariables=1
			]],
			i, i, i, i, i, i)
		)
				
	end
	
	-- string gsub to remove the annoying tab characters that get set because of the mess we've written
	-- the `X, _` is because `:write` also adds the tuple, which we don't want
	local ConcatonatedTable, _ = string.gsub(table.concat(Events2Sections, "\n"), "\t", "")
	FILE:write(ConcatonatedTable)
	FILE:close()
end

--[[
* Initialize function
	* Get If the File needs to be refreshed, we don't wanna waste I/O
		* If No, do nothing
		* If Yes, Generate the Events and Write them to File
* Events Handler
	* Initialize the array of Events regardless of situation
		* To get what events we have, we read the variable from the file
	* To remove Rvents, we could decrease the number of the list (what we're going with) or regenerate the file
	* To add new Events, we could do it in Rainmeter (what we're going with) or do it in Lua
]]


function Initialize()
	Events.GenerateArrayFromFile()
	if SELF:GetOption("ToRefresh", "1") == "1" then
		GenerateMetersFile()
		SKIN:Bang("!WriteKeyValue", SELF:GetName(), "ToRefresh", "0")
		SKIN:Bang("!Refresh")
	else
		SKIN:Bang("!HideMeter", "ErrorString")
	end
end

