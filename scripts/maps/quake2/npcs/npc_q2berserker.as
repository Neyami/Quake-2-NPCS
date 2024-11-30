namespace npc_q2berserker
{

const string NPC_MODEL				= "models/quake2/monsters/berserker/berserker.mdl";
const string MODEL_GIB_BONE		= "models/quake2/objects/gibs/bone.mdl";
const string MODEL_GIB_GEAR		= "models/quake2/objects/gibs/gear.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/berserker/gibs/chest.mdl";
const string MODEL_GIB_HAMMER	= "models/quake2/monsters/berserker/gibs/hammer.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/berserker/gibs/head.mdl";
const string MODEL_GIB_THIGH		= "models/quake2/monsters/berserker/gibs/thigh.mdl";

const Vector NPC_MINS					= Vector( -16, -16, 0 );
const Vector NPC_MAXS					= Vector( 16, 16, 80 ); //56 in original

const int NPC_HEALTH					= 240;

const int AE_ATTACK_SPIKE			= 6;
const int AE_ATTACK_CLUB				= 7;
const int AE_FLINCHRESET				= 8;

const float SPIKE_DMG_MIN			= 5.0;
const float SPIKE_DMG_MAX			= 11.0;
const float CLUB_DMG_MIN			= 15.0;
const float CLUB_DMG_MAX			= 21.0;
const float MELEE_KICK_SPIKE		= 100.0;
const float MELEE_KICK_CLUB		= 400.0;

const array<string> arrsNPCSounds =
{
	"quake2/misc/udeath.wav",
	"quake2/npcs/berserker/beridle1.wav",
	"quake2/npcs/berserker/idle.wav",
	"quake2/npcs/berserker/sight.wav",
	"quake2/npcs/berserker/bersrch1.wav",
	"quake2/npcs/berserker/attack.wav",
	"quake2/npcs/berserker/berpain2.wav",
	"quake2/npcs/berserker/berdeth2.wav"
};

enum q2sounds_e
{
	SND_DEATH_GIB = 0,
	SND_IDLE1,
	SND_IDLE2,
	SND_SIGHT,
	SND_SEARCH,
	SND_ATTACK,
	SND_PAIN,
	SND_DEATH
};

enum anim_e
{
	ANIM_PAIN1 = 11,
	ANIM_PAIN2,
	ANIM_DEATH1,
	ANIM_DEATH2
};

final class npc_q2berserker : CBaseQ2NPC
{
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, NPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, NPC_MINS, NPC_MAXS );

		pev.health						= NPC_HEALTH;
		pev.solid						= SOLID_SLIDEBOX;
		pev.movetype				= MOVETYPE_STEP;
		self.m_bloodColor			= BLOOD_COLOR_RED;
		self.m_flFieldOfView		= 0.5;
		self.m_afCapability			= bits_CAP_DOORS_GROUP;

		if( string(self.m_FormattedName).IsEmpty() )
			self.m_FormattedName	= "Berserker";

		m_flGibHealth = -60.0;

		if( q2::g_iChaosMode == q2::CHAOS_LEVEL1 )
		{
			if( q2::g_iDifficulty < q2::DIFF_NIGHTMARE )
				m_iWeaponType = Math.RandomLong( q2::WEAPON_BULLET, q2::WEAPON_RAILGUN );
			else
				m_iWeaponType = Math.RandomLong( q2::WEAPON_BULLET, q2::WEAPON_BFG );
		}

		self.MonsterInit();

		if( self.IsPlayerAlly() )
			SetUse( UseFunction(this.FollowerUse) );
	}

	void Precache()
	{
		uint i;

		g_Game.PrecacheModel( NPC_MODEL );
		g_Game.PrecacheModel( MODEL_GIB_BONE );
		g_Game.PrecacheModel( MODEL_GIB_GEAR );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_HAMMER );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );
		g_Game.PrecacheModel( MODEL_GIB_THIGH );

		for( i = 0; i < arrsNPCSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( arrsNPCSounds[i] );
	}

	void FollowerUse( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		self.FollowerPlayerUse( pActivator, pCaller, useType, flValue );
	}

	void SetYawSpeed() //SUPER IMPORTANT, NPC WON'T DO ANYTHING WITHOUT THIS :aRage:
	{
		int ys = 120;
		pev.yaw_speed = ys;
	}

	int Classify()
	{
		if( self.IsPlayerAlly() ) 
			return CLASS_PLAYER_ALLY;

		return CLASS_ALIEN_MILITARY;
	}

	void AlertSound()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SIGHT], VOL_NORM, ATTN_NORM );
	}

	void SearchSound()
	{
		if( Math.RandomLong(0, 1) == 1 )
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_IDLE2], VOL_NORM, ATTN_NORM );
		else
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SEARCH], VOL_NORM, ATTN_NORM );
	}

	void HandleAnimEventQ2( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case AE_ATTACK_SPIKE:
			{
				MeleeAttack();
				break;
			}

			case AE_ATTACK_CLUB:
			{
				MeleeAttack( true );
				break;
			}

			case AE_FLINCHRESET:
			{
				self.SetActivity( ACT_RESET );
				break;
			}
		}
	}

	void MeleeAttack( bool bClubAttack = false )
	{
		float flDamage = Math.RandomFloat( SPIKE_DMG_MIN, SPIKE_DMG_MAX );
		if( bClubAttack ) flDamage = Math.RandomFloat( CLUB_DMG_MIN, CLUB_DMG_MAX );

		CBaseEntity@ pHurt = CheckTraceHullAttack( Q2_MELEE_DISTANCE, flDamage, DMG_SLASH );
		if( pHurt !is null )
		{
			if( pHurt.pev.FlagBitSet(FL_MONSTER) or pHurt.pev.FlagBitSet(FL_CLIENT) )
			{
				Math.MakeVectors( pev.angles );

				if( bClubAttack )
				{
					pHurt.pev.punchangle.z = 18;
					pHurt.pev.punchangle.x = 5;
					pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_right * MELEE_KICK_CLUB;
				}
				else
				{
					pHurt.pev.punchangle.x = 5;
					pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * MELEE_KICK_SPIKE + g_Engine.v_up * (MELEE_KICK_SPIKE * 3.0);
				}
			}
		}
		else
		{
			if( bClubAttack )
				m_flMeleeCooldown = g_Engine.time + 2.5;
			else
				m_flMeleeCooldown = g_Engine.time + 1.2;
		}
	}

	bool CheckMeleeAttack2( float flDot, float flDist ) { return false; }
	bool CheckRangeAttack2( float flDot, float flDist ) { return false; }

	bool CheckMeleeAttack1( float flDot, float flDist )
	{
		if( flDist <= 64 and flDot >= 0.7 and self.m_hEnemy.IsValid() and self.m_hEnemy.GetEntity().pev.FlagBitSet(FL_ONGROUND) and g_Engine.time > m_flMeleeCooldown )
			return true;

		return false;
	}

	bool CheckRangeAttack1( float flDot, float flDist ) //flDist > 64 and flDist <= 784 and flDot >= 0.5
	{
		//if( M_CheckAttack(flDist) )
			//return true;

		return false;
	}

	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		pevAttacker.frags += ( flDamage/90 );

		HandlePain( flDamage );

		return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
	}

	void HandlePain( float flDamage )
	{
		pev.dmg = flDamage;

		if( pev.deadflag != DEAD_NO ) return;

		if( pev.health < (pev.max_health / 2) )
			pev.skin |= 1;

		// if we're jumping, don't pain
		/*if ((self.monsterinfo.active_move == &berserk_move_jump) ||
			(self.monsterinfo.active_move == &berserk_move_jump2) ||
			(self.monsterinfo.active_move == &berserk_move_attack_strike))
		{
			return;
		}*/

		if( g_Engine.time < pev.pain_finished )
			return;

		pev.pain_finished = g_Engine.time + 3.0;

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN], VOL_NORM, ATTN_NORM );

		if( !M_ShouldReactToPain() )
			return;

		if( flDamage <= 50 or Math.RandomFloat(0.0, 1.0) < 0.5 )
			SetAnim( ANIM_PAIN1 );
		else
			SetAnim( ANIM_PAIN2 );
	}

	void StartTask( Task@ pTask )
	{
		switch( pTask.iTask )
		{
			case TASK_DIE:
			{
				if( pev.dmg >= 50 )
					SetAnim( ANIM_DEATH1 );
				else
					SetAnim( ANIM_DEATH2 );

				break;
			}

			default:
			{			
				BaseClass.StartTask( pTask );
				break;
			}
		}
	}

	void GibMonster()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_DEATH_GIB], VOL_NORM, ATTN_NORM );

		ThrowGib( 2, MODEL_GIB_BONE, pev.dmg, -1, BREAK_FLESH );
		ThrowGib( 3, MODEL_GIB_MEAT, pev.dmg, -1, BREAK_FLESH );
		ThrowGib( 1, MODEL_GIB_GEAR, pev.dmg, -1, BREAK_METAL );
		ThrowGib( 1, MODEL_GIB_CHEST, pev.dmg, 2, BREAK_FLESH );
		ThrowGib( 1, MODEL_GIB_HAMMER, pev.dmg, 10, BREAK_CONCRETE );
		ThrowGib( 1, MODEL_GIB_THIGH, pev.dmg, Math.RandomLong(0, 1) == 0 ? 11 : 15, BREAK_FLESH );
		ThrowGib( 1, MODEL_GIB_HEAD, pev.dmg, 3, BREAK_FLESH );

		SetThink( ThinkFunction(this.SUB_Remove) );
		pev.nextthink = g_Engine.time;
	}
 
	void SUB_Remove()
	{
		self.UpdateOnRemove();

		if( pev.health > 0 )
		{
			// this situation can screw up monsters who can't tell their entity pointers are invalid.
			pev.health = 0;
		}

		g_EntityFuncs.Remove(self);
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "npc_q2berserker::npc_q2berserker", "npc_q2berserker" );
	g_Game.PrecacheOther( "npc_q2berserker" );
}

} //end of namespace npc_q2berserker

/* FIXME
*/

/* TODO
	Add stuff from rerelease ??
*/