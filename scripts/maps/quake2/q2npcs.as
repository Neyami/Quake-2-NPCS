#include "npcs/q2npccommon"
#include "npcs/q2npcentities"

#include "npcs/npc_q2soldier"

void MapInit()
{
	npc_q2soldier::Register();

	g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @q2::PlayerTakeDamage );
}

namespace q2
{

const array<string> g_arrsQ2Monsters =
{
	"npc_q2soldier",
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