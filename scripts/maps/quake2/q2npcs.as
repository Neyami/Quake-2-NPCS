#include "npcs/q2npccommon"
#include "npcs/q2npcentities"

#include "npcs/npc_q2soldier"
#include "npcs/npc_q2enforcer"

//for stadium4q2
#include "../stadium4/env_te"
#include "../stadium4/game_monstercounter"
#include "../stadium4/trigger_random_position"

void MapInit()
{
	q2::g_ChaosMode = q2::CHAOS_NONE;

	q2::RegisterNPCRailbeam();
	q2::RegisterNPCLaser();
	q2::RegisterNPCGrenade();
	q2::RegisterNPCRocket();
	q2::RegisterNPCBFG();

	npc_q2soldier::Register();
	npc_q2enforcer::Register();

	//for stadium4q2
	g_CustomEntityFuncs.RegisterCustomEntity( "env_te_teleport", "env_te_teleport" );
	g_CustomEntityFuncs.RegisterCustomEntity( "game_monstercounter", "game_monstercounter" );
	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_random_position", "trigger_random_position" );

	g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @q2::PlayerTakeDamage );
}

namespace q2
{

int g_ChaosMode;

const Vector DEFAULT_BULLET_SPREAD = VECTOR_CONE_3DEGREES;
const Vector DEFAULT_SHOTGUN_SPREAD = VECTOR_CONE_5DEGREES;

const array<string> g_arrsQ2Monsters =
{
	"npc_q2soldier",
	"npc_q2enforcer",
	"npc_q2berserker",
	"npc_q2gladiator",
	"npc_q2tank"
};

const array<string> g_arrsQ2Projectiles =
{
	"q2lasernpc",
	"q2rocketnpc",
	"q2grenadenpc",
	"q2bfgnpc"
};

enum animev_e
{
	AE_IDLESOUND = 3,
	AE_WALKMOVE,
	AE_FOOTSTEP
};

enum diff_e
{
	DIFF_EASY = 0,
	DIFF_MEDIUM,
	DIFF_HARD,
	DIFF_NIGHTMARE
};

/*
0 = npc weapons are normal
1 = npc weapons are randomly decided at spawn
2 = npc weapons are random on every shot
*/
enum chaos_e
{
	CHAOS_NONE = 0,
	CHAOS_LEVEL1,
	CHAOS_LEVEL2
};

enum weapons_e
{
	WEAPON_BULLET = 0,
	WEAPON_SHOTGUN,
	WEAPON_BLASTER,
	WEAPON_GRENADE,
	WEAPON_ROCKET,
	WEAPON_RAILGUN,
	WEAPON_BFG
};

HookReturnCode PlayerTakeDamage( DamageInfo@ pDamageInfo )
{
	/*g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "[PTDT] pVictim: " + pDamageInfo.pVictim.GetClassname() + "\n" );
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "[PTDT] Damage Type: " + pDamageInfo.bitsDamageType + "\n" );
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "[PTDT] Damage Amount: " + pDamageInfo.flDamage + "\n" );
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "[PTDT] pAttacker: " + pDamageInfo.pAttacker.GetClassname() + "\n" );
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "[PTDT] pInflictor: " + pDamageInfo.pInflictor.GetClassname() + "\n" );*/

	//TODO TIDY THIS UP
	if( g_arrsQ2Projectiles.find(pDamageInfo.pInflictor.GetClassname()) >= 0 )
	{
		CBasePlayer@ pVictim = cast<CBasePlayer@>( pDamageInfo.pVictim );
		CBaseEntity@ pProjectile = pDamageInfo.pInflictor;

		if( pVictim.IsAlive() and pDamageInfo.flDamage >= pVictim.pev.health )
		{
			if( ((pDamageInfo.bitsDamageType & DMG_NEVERGIB) == 0 and pVictim.pev.health < -30) or (pDamageInfo.bitsDamageType & DMG_ALWAYSGIB) != 0 ) 
			{
				pVictim.GibMonster();
				pVictim.pev.effects |= EF_NODRAW;
			}

			pVictim.Killed( null, GIB_NOPENALTY );
			pVictim.m_iDeaths++;

			string sDeathMsg;

			if( pProjectile.GetClassname() == "q2lasernpc" )
			{
				if( pProjectile.pev.targetname == "npc_q2soldier" )
					sDeathMsg = string(pVictim.pev.netname) + " was blasted by a Light Guard\n";
				else if( pProjectile.pev.targetname == "npc_q2tank" )
					sDeathMsg = string(pVictim.pev.netname) + " was blasted by a Tank\n";
			}
			else if( pProjectile.GetClassname() == "q2rocketnpc" )
			{
				if( pProjectile.pev.targetname == "npc_q2tank" )
				{
					if( Math.RandomLong(1, 10) <= 5 )
						sDeathMsg = string(pVictim.pev.netname) + " almost dodged a Tank's rocket\n";
					else
						sDeathMsg = string(pVictim.pev.netname) + " ate a Tank's rocket\n";
				}
			}

			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, sDeathMsg );

			return HOOK_CONTINUE;
		}
	}

	if( g_arrsQ2Monsters.find(pDamageInfo.pAttacker.GetClassname()) >= 0 )
	{
		CBasePlayer@ pVictim = cast<CBasePlayer@>( pDamageInfo.pVictim );

		if( pVictim.IsAlive() and pDamageInfo.flDamage >= pVictim.pev.health )
		{
			if( ((pDamageInfo.bitsDamageType & DMG_NEVERGIB) == 0 and pVictim.pev.health < -30) or (pDamageInfo.bitsDamageType & DMG_ALWAYSGIB) != 0 ) 
			{
				pVictim.GibMonster();
				pVictim.pev.effects |= EF_NODRAW;
			}

			pVictim.Killed( null, GIB_NOPENALTY );
			pVictim.m_iDeaths++;

			string sDeathMsg;

			if( pDamageInfo.pAttacker.GetClassname() == "npc_q2soldier" )
			{
				if( pDamageInfo.pAttacker.pev.weapons == 1 )
					sDeathMsg = string(pVictim.pev.netname) + " was gunned down by a Shotgun Guard\n";
				else
					sDeathMsg = string(pVictim.pev.netname) + " was machine-gunned by a Machinegun Guard\n";
			}
			else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2enforcer" )
			{
				if( (pDamageInfo.bitsDamageType & DMG_BULLET) != 0 )
					sDeathMsg = string(pVictim.pev.netname) + " was pumped full of lead by an Enforcer\n";
				else
					sDeathMsg = string(pVictim.pev.netname) + " was bludgeoned by an Enforcer\n";
			}
			else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2berserker" )
				sDeathMsg = string(pVictim.pev.netname) + " was smashed by a Berserker\n";
			else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2gladiator" )
			{
				if( (pDamageInfo.bitsDamageType & DMG_ENERGYBEAM) != 0 )
					sDeathMsg = string(pVictim.pev.netname) + " was railed by a Gladiator\n";
				else
					sDeathMsg = string(pVictim.pev.netname) + " was mangled by a Gladiator's claw\n";
			}
			else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2tank" )
			{
				if( (pDamageInfo.bitsDamageType & DMG_BULLET) != 0 )
					sDeathMsg = string(pVictim.pev.netname) + " was pumped full of lead by a Tank\n";
			}

			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, sDeathMsg );
		}
	}

	return HOOK_CONTINUE;
}

} //end of namespace q2