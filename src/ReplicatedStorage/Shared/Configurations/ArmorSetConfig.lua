--!strict

export type SetBonus = {
	PiecesRequired: number,
	StatBonuses: {[string]: number}?,
	Description: string,
}

export type ArmorSet = {
	Name: string,
	Culture: string?,
	Bonuses: {SetBonus},
}

local ArmorSets: {[string]: ArmorSet} = {
	ItalianPlate = {
		Name = "Italian Plate",
		Culture = "Italian",
		Bonuses = {
			{
				PiecesRequired = 2,
				StatBonuses = {
					Agility = 10,
				},
				Description = "+10 Agility",
			},
			{
				PiecesRequired = 3,
				StatBonuses = {
					MovementSpeed = 15,
				},
				Description = "+15% Movement Speed",
			},
		},
	},

	GermanGothic = {
		Name = "German Gothic",
		Culture = "German",
		Bonuses = {
			{
				PiecesRequired = 2,
				StatBonuses = {
					Health = 20,
				},
				Description = "+20 Health",
			},
			{
				PiecesRequired = 4,
				StatBonuses = {
					PhysicalResistance = 10,
				},
				Description = "+10 Physical Resistance",
			},
		},
	},

	EnglishBrigandine = {
		Name = "English Brigandine",
		Culture = "English",
		Bonuses = {
			{
				PiecesRequired = 2,
				StatBonuses = {
					Agility = 5,
					Stamina = 10,
				},
				Description = "+5 Agility, +10 Stamina",
			},
			{
				PiecesRequired = 3,
				StatBonuses = {
					DodgeCost = -5,
				},
				Description = "-5 Dodge Stamina Cost",
			},
		},
	},
}

local ArmorSetConfig = {}

function ArmorSetConfig.GetSet(SetName: string): ArmorSet?
	return ArmorSets[SetName]
end

function ArmorSetConfig.GetAllSets(): {[string]: ArmorSet}
	return ArmorSets
end

return ArmorSetConfig