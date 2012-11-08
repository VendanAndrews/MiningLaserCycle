objectdef obj_Configuration_MiningLaserCycle
{
	variable string SetName = "MiningLaserCycle"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:Update["obj_Configuration", " ${This.SetName} settings missing - initializing", "o"]
			This:Set_Default_Values[]
		}
		UI:Update["obj_Configuration", " ${This.SetName}: Initialized", "-g"]
	}

	member:settingsetref CommonRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

		This.CommonRef:AddSetting[CycleTime, 45]
	}

	Setting(int, CycleTime, SetCycleTime)
	
}

objectdef obj_MiningLaserCycle inherits obj_State
{
	variable obj_Configuration_MiningLaserCycle Config
	variable set RegisteredActiveLasers
	
	method Initialize()
	{
		This[parent]:Initialize
		;This.NonGameTiedPulse:Set[TRUE]
		DynamicAddMiniMode("MiningLaserCycle", "MiningLaserCycle")
	}
	
	method Start()
	{
		This:QueueState["MiningLaserCycle"]
	}
	
	method Stop()
	{
		This:Clear
	}
	
	

	
	; remove \/
	member:bool IsAllreadyRegistered(obj_module target_module)
	{
		variable iterator active_iterator
		RegisteredActiveLasers:GetIterator[active_iterator]
		
		if ${active_iterator:First(exists)}
		{
			do
			{
				if ${active_iterator.Value} == ${target_module}
				{
					return TRUE
				}
			}
			while ${active_iterator:Next(exists)}
		}
		
		return FALSE
	}
	
	
	method DeactivateLaser(obj_Module module_to_deactivate)
	{
		UI:Update["obj_MiningLaserCycle","Cycling Laser","-g"]
		RegisteredActiveLasers:Remove[${module_to_deactivate}]
		module_to_deactivate:Deactivate[]
		Delay:RegisterAction["MiningLaserCycle:ActivateLaser[${ml_iterator.Value}, ${module_to_deactivate.CurrentTarget}]",2000]
		; ignore if laser no longer exists
		; ignore if laser has been removed
		; ignore if laser is allready off
	}

	method ActivateLaser(obj_Module module_to_deactivate, int64 Target)
	{
		module_to_deactivate:Activate[${Target}]
	}
	
	member:bool MiningLaserCycle()
	{
		if ${Ship.ModuleList_MiningLaser.ActiveCount}
		{
			;  common case : all lasers running all lasers registered
			if ${Ship.ModuleList_MiningLaser.ActiveCount} == ${RegisteredActiveLasers.Used}
			{
				return FALSE
			}
			
			; iterate over the list of mining lasers
			variable iterator ml_iterator
			Ship.ModuleList_MiningLaser:GetIterator[ml_iterator]
			
			if ${ml_iterator:First(exists)}
			{
				do
				{
					if ${ml_iterator.Value.IsActive}
					{
						; ignore a registered active laser
						if !${RegisteredActiveLasers.Contains[${ml_iterator.Value}]}
						{
							RegisteredActiveLasers:Add[${ml_iterator.Value}]
; TODO ->					; deactivate laser in 45 miliseconds TODO: make configureable (currently 5 seconds}
							Delay:RegisterAction["MiningLaserCycle:DeactivateLaser[${ml_iterator.Value}]",${Math.Calc[${Config.CycleTime} * 1000]}]
						}
					}
					else
					{
						RegisteredActiveLasers:Remove[${ml_iterator.Value}]
					}
				}
				while ${ml_iterator:Next(exists)}
			}
		}
		
		return FALSE
	}
}