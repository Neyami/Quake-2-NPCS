namespace npc_q2ironmaiden
{

const string NPC_MODEL				= "models/quake2/monsters/ironmaiden/ironmaiden.mdl";
const string MODEL_GIB_BONE		= "models/quake2/objects/gibs/bone.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_ARM			= "models/quake2/monsters/ironmaiden/gibs/arm.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/ironmaiden/gibs/chest.mdl";
const string MODEL_GIB_FOOT		= "models/quake2/monsters/ironmaiden/gibs/foot.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/ironmaiden/gibs/head.mdl";
const string MODEL_GIB_TUBE		= "models/quake2/monsters/ironmaiden/gibs/tube.mdl";

const Vector NPC_MINS					= Vector( -16, -16, 0 );
const Vector NPC_MAXS					= Vector( 16, 16, 80 ); //56 in original

const int NPC_HEALTH					= 175;

const int AE_MELEE						= 6;
const int AE_MELEE_REFIRE			= 7;
const int AE_ROCKET_LAUNCH		= 8;
const int AE_ROCKET_REFIRE			= 9;

const float MELEE_DMG_MIN			= 10.0;
const float MELEE_DMG_MAX			= 16.0;
const float MELEE_KICK					= 80.0;

const float ROCKET_DMG				= 50;
const float ROCKET_SPEED				= 750;

const array<string> arrsNPCSounds =
{
	"quake2/misc/udeath.wav",
	"quake2/npcs/ironmaiden/chkidle1.wav",
	"quake2/npcs/ironmaiden/chkidle2.wav",
	"quake2/npcs/ironmaiden/chksght1.wav",
	"quake2/npcs/ironmaiden/chksrch1.wav",
	"quake2/npcs/ironmaiden/chkatck2.wav",
	"quake2/npcs/ironmaiden/chkatck3.wav",
	"quake2/npcs/ironmaiden/chkatck4.wav",
	"quake2/npcs/ironmaiden/chkpain1.wav",
	"quake2/npcs/ironmaiden/chkpain2.wav",
	"quake2/npcs/ironmaiden/chkpain3.wav",
	"quake2/npcs/ironmaiden/chkdeth1.wav",
	"quake2/npcs/ironmaiden/chkdeth2.wav",
	"quake2/npcs/ironmaiden/chkatck1.wav",
	"quake2/npcs/ironmaiden/chkatck3.wav",
	"quake2/npcs/ironmaiden/chkatck4.wav",
	"quake2/npcs/ironmaiden/chkatck5.wav"
};

enum q2sounds_e
{
	SND_DEATH_GIB = 0,
	SND_IDLE1,
	SND_IDLE2,
	SND_SIGHT,
	SND_SEARCH,
	SND_ROCKET_LAUNCH,
	SND_MELEE_SWING,
	SND_MELEE_HIT,
	SND_PAIN1,
	SND_PAIN2,
	SND_PAIN3
};

enum anim_e
{
	ANIM_PAIN1 = 6,
	ANIM_PAIN2,
	ANIM_PAIN3
};

final class npc_q2ironmaiden : CBaseQ2NPC
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
			self.m_FormattedName	= "Iron Maiden";

		m_flGibHealth = -70.0;

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
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_ARM );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_FOOT );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );
		g_Game.PrecacheModel( MODEL_GIB_TUBE );

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
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SEARCH], VOL_NORM, ATTN_NORM );
	}

	void HandleAnimEventQ2( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case q2::AE_IDLESOUND:
			{
				ChickMoan();

				break;
			}

			case AE_MELEE:
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MELEE_SWING], VOL_NORM, ATTN_IDLE );

				int iDamage = Math.RandomLong( MELEE_DMG_MIN, MELEE_DMG_MAX );

				CBaseEntity@ pHurt = CheckTraceHullAttack( Q2_MELEE_DISTANCE, iDamage, DMG_SLASH );
				if( pHurt !is null )
				{
					if( pHurt.pev.FlagBitSet(FL_MONSTER) or pHurt.pev.FlagBitSet(FL_CLIENT) )
					{
						pHurt.pev.punchangle.x = 5;
						Math.MakeVectors( pev.angles );
						pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * MELEE_KICK;
					}

					g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_MELEE_HIT], VOL_NORM, ATTN_NORM );
				}

				break;
			}

			case AE_MELEE_REFIRE:
			{
				if( self.m_hEnemy.IsValid() and self.m_hEnemy.GetEntity().pev.health > 0 )
				{
					if( (pev.origin - self.m_hEnemy.GetEntity().pev.origin).Length() <= Q2_MELEE_DISTANCE and Math.RandomFloat(0.0, 1.0) <= 0.9 )
						SetFrame( 16, 3 );
				}

				break;
			}

			case AE_ROCKET_LAUNCH:
			{
				ChickRocket();
				break;
			}

			case AE_ROCKET_REFIRE:
			{
				if( self.m_hEnemy.IsValid() and self.m_hEnemy.GetEntity().pev.health > 0 )
				{
					if( (pev.origin - self.m_hEnemy.GetEntity().pev.origin).Length() > Q2_RANGE_MELEE and self.FVisible(self.m_hEnemy, true) and Math.RandomFloat(0.0, 1.0) <= 0.6 )
						SetFrame( 32, 11 );
				}

				break;
			}
		}
	}

	void ChickMoan()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[Math.RandomLong(SND_IDLE1, SND_IDLE2)], VOL_NORM, ATTN_IDLE );
	}

	void ChickRocket()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_ROCKET_LAUNCH], VOL_NORM, ATTN_NORM );

		Vector vecMuzzle, vecAim;

		if( self.m_hEnemy.IsValid() )
		{
			self.GetAttachment( 0, vecMuzzle, void );

			// don't shoot at feet if they're above where i'm shooting from.
			if( Math.RandomFloat(0.0, 1.0) < 0.33 or vecMuzzle.z < self.m_hEnemy.GetEntity().pev.absmin.z )
			{
				Vector vecEnemyOrigin = self.m_hEnemy.GetEntity().pev.origin;
				vecEnemyOrigin.z += self.m_hEnemy.GetEntity().pev.view_ofs.z;
				vecAim = (vecEnemyOrigin - vecMuzzle).Normalize();
			}
			else
			{
				Vector vecEnemyOrigin = self.m_hEnemy.GetEntity().pev.origin;
				vecEnemyOrigin.z = self.m_hEnemy.GetEntity().pev.absmin.z + 1;
				vecAim = (vecEnemyOrigin - vecMuzzle).Normalize();
			}

			Vector vecTrace;

			if( Math.RandomFloat(0.0, 1.0) < 0.35 )
				PredictAim( self.m_hEnemy, vecMuzzle, ROCKET_SPEED, false, 0.0, vecAim, vecTrace );

			TraceResult tr;
			g_Utility.TraceLine( vecMuzzle, vecTrace, missile, self.edict(), tr );
			if( tr.flFraction > 0.5 or tr.fAllSolid == 0 ) //trace.ent->solid != SOLID_BSP
			{
				monster_muzzleflash( vecMuzzle, 255, 128, 51 );
				monster_fire_weapon( q2::WEAPON_ROCKET, vecMuzzle, vecAim, ROCKET_DMG, ROCKET_SPEED );
			}
		}
	}

	bool CheckMeleeAttack2( float flDot, float flDist ) { return false; }
	bool CheckRangeAttack2( float flDot, float flDist ) { return false; }

	bool CheckMeleeAttack1( float flDot, float flDist )
	{
		if( flDist <= 64 and flDot >= 0.7 and self.m_hEnemy.IsValid() and self.m_hEnemy.GetEntity().pev.FlagBitSet(FL_ONGROUND) )
			return true;

		return false;
	}

	bool CheckRangeAttack1( float flDot, float flDist ) //flDist > 64 and flDist <= 784 and flDot >= 0.5
	{
		if( M_CheckAttack(flDist) )
			return true;

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

		if( g_Engine.time < pev.pain_finished )
			return;

		pev.pain_finished = g_Engine.time + 3.0;

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[Math.RandomLong(SND_PAIN1, SND_PAIN3)], VOL_NORM, ATTN_NORM );

		if( !M_ShouldReactToPain() )
			return; // no pain anims in nightmare

		if( flDamage <= 10 )
			SetAnim( ANIM_PAIN1 );
		else if( flDamage <= 25 )
			SetAnim( ANIM_PAIN2 );
		else
			SetAnim( ANIM_PAIN3 );
	}

	void GibMonster()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_DEATH_GIB], VOL_NORM, ATTN_NORM );

		ThrowGib( 2, MODEL_GIB_BONE, pev.dmg, -1, BREAK_FLESH );
		ThrowGib( 3, MODEL_GIB_MEAT, pev.dmg, -1, BREAK_FLESH );
		ThrowGib( 1, MODEL_GIB_ARM, pev.dmg, 24, BREAK_FLESH );
		ThrowGib( 1, MODEL_GIB_FOOT, pev.dmg, Math.RandomLong(0, 1) == 0 ? 33 : 36, BREAK_FLESH );
		ThrowGib( 1, MODEL_GIB_TUBE, pev.dmg, 5 );
		ThrowGib( 1, MODEL_GIB_CHEST, pev.dmg, 2, BREAK_FLESH );
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
	q2::RegisterProjectile( "rocket" );

	g_CustomEntityFuncs.RegisterCustomEntity( "npc_q2ironmaiden::npc_q2ironmaiden", "npc_q2ironmaiden" );
	g_Game.PrecacheOther( "npc_q2ironmaiden" );
}

} //end of namespace npc_q2ironmaiden

/* FIXME
*/

/* TODO
*/