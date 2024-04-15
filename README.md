

# Reputation
Guide.

## Reputation SQL
```sql
CREATE TABLE `player_reputation` (
	`citizenid` VARCHAR(55) NOT NULL COLLATE 'utf8mb4_general_ci',
	`reputation` LONGTEXT NOT NULL COLLATE 'utf8mb4_bin',
	PRIMARY KEY (`citizenid`) USING BTREE,
	UNIQUE INDEX `citizenid` (`citizenid`) USING BTREE,
	CONSTRAINT `reputation` CHECK (json_valid(`reputation`))
)
COLLATE='utf8mb4_general_ci'
ENGINE=InnoDB
;

CREATE TABLE `reputation_boosts` (
	`transactionId` INT(11) NOT NULL,
	`redeemed` INT(11) NOT NULL,
	`license` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`type` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`multiplier` INT(11) NOT NULL,
	`targets` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_unicode_ci',
	`created` INT(11) NOT NULL,
	`activated` BIT(1) NOT NULL DEFAULT b'0'
)
```

## Reputation Exports
```
-- Gets all Player reputations and values
exports.reputation:GetRep(citizenid)

-- Gets a singluar rep and value.
exports.reputation:GetRep(citizenid, reputationName)

-- Sets the reputation to the amount.
exports.reputation:SetRep(citizenid, reputationName, amountToSet)

-- Add amount to a reputation.
exports.reputation:AddRep(citizenid, reputationName, amountToAdd)

-- Add amounts from a list of reputations
---@param reputations : table { ['garbage'] = 25, ['fishing'] = 5  }
exports.reputation:AddMultipleRep(citizenid, reputations)

-- Remove amount from reputation (cannot go lower than zero)
exports.reputation:RemoveRep(citizenid, reputationName, amountToRemove)

-- Remove amounts from a list of reputations
---@param reputations : table { ['garbage'] = 25, ['fishing'] = 5  }
exports.reputation:RemoveMultipleRep(citizenid, reputations)
```