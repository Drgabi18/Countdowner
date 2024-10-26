Events = {
--[[
["Names"] = "",
["Date"] = Year-Month-Day,
["Time"] = Hour:Minute:Seconds
]]
}

NoOfEvents = 0

function RemoveEvent(index)
	table.remove(Events, index)
	NoOfEvents = #Events
	SKIN:Bang("!WriteKeyValue", "Variables", "Events", (NoOfEvents-1) )
	GenerateEvents(NoOfEvents, true)
end

function GenerateEvents(NoOfEvents, FromLua)
	if not FromLua then
		for i = 1, NoOfEvents do
			Name = SELF:GetOption("Name"..i)
			Date = SELF:GetOption("Date"..i)
			Time = SELF:GetOption("Time"..i)
			
			-- end of sections, break the loop
			if (Name == '') and (Date == '') and (Time == '') then break end
			
			-- if one is missing, error out
			if (Name == '') or (Date == '') or (Time == '') then assert("Invalid Name/Date/Time, make sure they're all filled correctly.") end
			
			Events[i] = {["Name"] = Name, ["Date"] = Date, ["Time"] = Time}
			
			--print(Name, Date, Time)
		end
	else
		print("Now creating events from Lua")
		for i,v in ipairs(Events) do
			print(i,v)
			SKIN:Bang("!WriteKeyValue", SELF:GetName(), "Name"..i, v["Name"], "Events.inc")
			SKIN:Bang("!WriteKeyValue", SELF:GetName(), "Date"..i, v["Date"], "Events.inc")
			SKIN:Bang("!WriteKeyValue", SELF:GetName(), "Time"..i, v["Time"], "Events.inc")
		end
		GenerateFile()
		SKIN:Bang("!Refresh")
	end
end

function GenerateFile()
	-- idk how to make an assert if file can't be opened
	local File = io.open(SKIN:MakePathAbsolute(SELF:GetOption("GeneratedFile")), "w")

	print("GenerateFile() No of Events", NoOfEvents)
	
	GenerateEvents(NoOfEvents, false)
	
	-- we start the necesary steps for writing to the file
	table.insert(Events2Sections,
	[[; ==============================
	; THIS FILE IS GENERATED AUTOMATICALLY THROUGH LUA
	; ANY CHANGES YOU WOULD MAKE WILL GET REMOVED
	; ONCE THE FILE REGENERATES
	; ==============================
	]]
	)
	
	print("GenerateFile() No of Events For Creating the Tables", NoOfEvents, #Events)
	
	for i=1, #Events do
		
		table.insert(Events2Sections,
			string.format(
			[[
			[TimestampMeasure%s]
			Measure=Time
			Timestamp=%sT%sZ
			TimeStampFormat=%%Y-%%m-%%dT%%H:%%M:%%SZ
			UpdateDivider=-1
			]],
			i, Events[i].Date, Events[i].Time)
		)
					
		table.insert(Events2Sections,
			string.format(
			[[
			[UptimeMeasure%s]
			Measure=Uptime
			SecondsValue=([TimestampMeasure%s:Timestamp]-[CurrentTime:Timestamp])
			Format=%s
			DynamicVariables=1
			]],
			i, i, SKIN:GetVariable("UptimeFormat", "%4!i!d %3!i!h %2!i!m %1!i!s"))
		)
		
		table.insert(Events2Sections,
			string.format(
			[[
			[ContainerMeterForList%s]
			Meter=Image
			H=(100*#Scale#)
			W=(400*#Scale#)
			SolidColor=000000
			X=(12*#Scale#)
			Y=(12*#Scale#)R
			UpdateDivider=-1
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
			Shape=Rectangle 0,0,400,100,4 | StrokeWidth 0 | Fill LinearGradient TheGradient | Scale #Scale#,#Scale#,0,0
			TheGradient=270 | #BackgroundFillSecondaryColor# ; -1.0 | #AccentColor# ; 10.0
			UpdateDivider=-1
			]],
			i, i)
		)
		
		-- preferably change this to a variable
		table.insert(Events2Sections,
			string.format(
			[[
			[MeterEventTitle%s]
			Meter=String
			Container=ContainerMeterForList%s
			Text=%s
			MeterStyle=NameStyle
			UpdateDivider=-1
			]],
			i, i, Events[i].Name)
		)
		
		table.insert(Events2Sections,
			string.format(
			[[
			[MeterSubtitleDate%s]
			Meter=String
			Container=ContainerMeterForList%s
			Text=%s
			MeterStyle=SubtitleStyle
			]],
			i, i, Events[i].Date)
		)
		
		table.insert(Events2Sections,
			string.format(
			[[
			[MeterSubtitleTime%s]
			Meter=String
			Container=ContainerMeterForList%s
			Text=%s
			MeterStyle=SubtitleStyle
			]],
			i, i, Events[i].Time)
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
			DynamicVariables=1
			]],
			i, i, i, i)
		)
		
		table.insert(Events2Sections,
			string.format(
			[[
			[MinusMeter%s]
			Meter=String
			Text=➖
			FontColor=FF0000
			Container=ContainerMeterForList%s
			X=R
			LeftMouseUpAction=[!CommandMeasure "Everything" "RemoveEvent(%s)"]
			]],
			i, i, i)
		)
		
	end
	
	-- string gsub to remove the annoying tab characters that get set because of the mess we've written
	File:write(string.gsub(table.concat(Events2Sections, "\n"), "\t", ""))
	File:close()
end

function Initialize()
	-- table which gets written to the file
	Events2Sections = {}
	NoOfEvents = SKIN:GetVariable("Events", 1)	
		
	if SELF:GetOption("ToRefresh", "1") == "1" then
		GenerateFile()
		SKIN:Bang("!WriteKeyValue", SELF:GetName(), "ToRefresh", "0")
		SKIN:Bang("!Refresh")
	else
		SKIN:Bang("!HideMeter", "ErrorString")
	end
	
	print("Initialize() function finished")
	print("Initialize() No of Events", #Events)
end