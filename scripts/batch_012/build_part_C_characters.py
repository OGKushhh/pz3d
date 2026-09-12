#!/usr/bin/env python3
"""Batch 012 — Part C — 5 DSL characters (zombies + NPCs).
Based on humanoid.mog skeleton style. Blocky but poseable."""
from pathlib import Path

BASE = Path("/home/z/my-project/assets")

def w(cat, name, content):
    d = BASE / cat / "src"
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{name}.mog").write_text(content)
    print(f"  wrote {cat}/{name}.mog")

# Shared skeleton helper — write a "rig" block consistent with humanoid.mog style
SKELETON = '''skeleton "rig" {
    bone "hips"      (pos=[0, 0.95, 0], envelope=0.30) {
      bone "spine"   (pos=[0, 0.25, 0], envelope=0.35) {
        bone "chest" (pos=[0, 0.25, 0], envelope=0.35) {
          bone "neck" (pos=[0, 0.10, 0], envelope=0.15) {
            bone "head" (pos=[0, 0.10, 0], envelope=0.20)
          }
          bone "shoulder_l" (pos=[-0.22, 0.05, 0], envelope=0.15) {
            bone "upper_arm_l" (pos=[0, -0.20, 0], envelope=0.12) {
              bone "forearm_l" (pos=[0, -0.25, 0], envelope=0.12)
            }
          }
          bone "shoulder_r" (pos=[ 0.22, 0.05, 0], envelope=0.15) {
            bone "upper_arm_r" (pos=[0, -0.20, 0], envelope=0.12) {
              bone "forearm_r" (pos=[0, -0.25, 0], envelope=0.12)
            }
          }
        }
      }
      bone "thigh_l" (pos=[-0.11, -0.05, 0], envelope=0.25) {
        bone "shin_l" (pos=[0, -0.45, 0], envelope=0.22) {
          bone "foot_l" (pos=[0, -0.42, 0.05], envelope=0.12)
        }
      }
      bone "thigh_r" (pos=[ 0.11, -0.05, 0], envelope=0.25) {
        bone "shin_r" (pos=[0, -0.45, 0], envelope=0.22) {
          bone "foot_r" (pos=[0, -0.42, 0.05], envelope=0.12)
        }
      }
    }
  }'''

# ============================================================
# walker_zombie_male — hunched male zombie, torn clothing, grey skin
# ============================================================
w("characters", "walker_zombie_male", '''// walker_zombie_male.mog — hunched male walker zombie
meta (name="walker_zombie_male", description="Hunched male walker zombie with torn shirt and grey-green skin, arms outstretched", tags=["character","zombie","walker","male","enemy","tier1"], mogen_version="0.1.12")
material "skin_zombie" (color=[0.50,0.55,0.42], roughness=0.85)
material "hair_dark" (color=[0.15,0.12,0.10], roughness=0.80)
material "shirt_torn" (color=[0.40,0.35,0.30], roughness=0.85, uv_mode="tile", uv_scale=2.0)
material "pants_dark" (color=[0.18,0.16,0.14], roughness=0.85)
material "boots_dark" (color=[0.10,0.08,0.06], roughness=0.6)
material "eyes_red" (color=[0.85,0.10,0.05], roughness=0.30, emissive=[0.7,0.10,0.05], emissive_strength=0.6)
material "blood_dark" (color=[0.30,0.05,0.05], roughness=0.95)
material "teeth_yellow" (color=[0.65,0.55,0.30], roughness=0.70)
scene {
  skeleton "rig" {
    bone "hips" (pos=[0, 0.95, 0], envelope=0.30) {
      bone "spine" (pos=[0, 0.20, 0.10], envelope=0.35) {
        bone "chest" (pos=[0, 0.20, 0.05], envelope=0.35) {
          bone "neck" (pos=[0, 0.10, -0.05], envelope=0.15) {
            bone "head" (pos=[0, 0.10, -0.02], envelope=0.20)
          }
          bone "shoulder_l" (pos=[-0.25, 0.05, 0], envelope=0.15) {
            bone "upper_arm_l" (pos=[0, -0.20, 0], envelope=0.12) {
              bone "forearm_l" (pos=[0.05, -0.25, 0], envelope=0.12)
            }
          }
          bone "shoulder_r" (pos=[ 0.25, 0.05, 0], envelope=0.15) {
            bone "upper_arm_r" (pos=[0, -0.20, 0], envelope=0.12) {
              bone "forearm_r" (pos=[-0.05, -0.25, 0], envelope=0.12)
            }
          }
        }
      }
      bone "thigh_l" (pos=[-0.13, -0.05, 0], envelope=0.25) {
        bone "shin_l" (pos=[0.02, -0.45, 0], envelope=0.22) {
          bone "foot_l" (pos=[0, -0.42, 0.05], envelope=0.12)
        }
      }
      bone "thigh_r" (pos=[ 0.13, -0.05, 0], envelope=0.25) {
        bone "shin_r" (pos=[-0.02, -0.45, 0], envelope=0.22) {
          bone "foot_r" (pos=[0, -0.42, 0.05], envelope=0.12)
        }
      }
    }
  }
  // Hunched body
  rounded_box "pelvis_mesh" (size=[0.32, 0.20, 0.22], radius=0.04, mat="pants_dark", pos=[0, 0.90, 0.05], skin="rig")
  rounded_box "torso_mesh" (size=[0.45, 0.55, 0.28], radius=0.05, mat="shirt_torn", pos=[0, 1.20, 0.10], skin="rig")
  rounded_box "head_mesh" (size=[0.22, 0.26, 0.22], radius=0.04, mat="skin_zombie", pos=[0, 1.55, 0.03], skin="rig")
  // Hair — patchy, just top of head
  box "hair_mesh" (size=[0.24, 0.06, 0.24], mat="hair_dark", pos=[0, 1.66, 0.03], skin="rig")
  // Eyes — glowing red
  sphere "eye_l" (radius=0.025, mat="eyes_red", pos=[-0.05, 1.56, 0.14], skin="rig")
  sphere "eye_r" (radius=0.025, mat="eyes_red", pos=[0.05, 1.56, 0.14], skin="rig")
  // Mouth — open, showing teeth
  box "mouth_open" (size=[0.12, 0.06, 0.04], mat="blood_dark", pos=[0, 1.46, 0.14], skin="rig")
  box "teeth_top" (size=[0.10, 0.02, 0.02], mat="teeth_yellow", pos=[0, 1.48, 0.13], skin="rig")
  box "teeth_bot" (size=[0.10, 0.02, 0.02], mat="teeth_yellow", pos=[0, 1.44, 0.13], skin="rig")
  // Arms — outstretched forward (zombie pose)
  rounded_box "upper_arm_l" (size=[0.14, 0.30, 0.14], radius=0.04, mat="shirt_torn", pos=[-0.30, 1.20, 0.20], rot=[60,0,0], skin="rig")
  rounded_box "forearm_l" (size=[0.12, 0.30, 0.12], radius=0.04, mat="skin_zombie", pos=[-0.30, 1.00, 0.45], rot=[60,0,0], skin="rig")
  rounded_box "hand_l" (size=[0.10, 0.12, 0.06], radius=0.03, mat="skin_zombie", pos=[-0.30, 0.85, 0.65], skin="rig")
  rounded_box "upper_arm_r" (size=[0.14, 0.30, 0.14], radius=0.04, mat="shirt_torn", pos=[0.30, 1.20, 0.20], rot=[60,0,0], skin="rig")
  rounded_box "forearm_r" (size=[0.12, 0.30, 0.12], radius=0.04, mat="skin_zombie", pos=[0.30, 1.00, 0.45], rot=[60,0,0], skin="rig")
  rounded_box "hand_r" (size=[0.10, 0.12, 0.06], radius=0.03, mat="skin_zombie", pos=[0.30, 0.85, 0.65], skin="rig")
  // Legs — slight stagger
  rounded_box "thigh_l" (size=[0.16, 0.45, 0.16], radius=0.05, mat="pants_dark", pos=[-0.13, 0.65, 0.05], rot=[5,0,0], skin="rig")
  rounded_box "shin_l" (size=[0.14, 0.40, 0.14], radius=0.04, mat="pants_dark", pos=[-0.13, 0.20, 0.10], skin="rig")
  rounded_box "foot_l" (size=[0.16, 0.10, 0.30], radius=0.03, mat="boots_dark", pos=[-0.13, 0.00, 0.18], skin="rig")
  rounded_box "thigh_r" (size=[0.16, 0.45, 0.16], radius=0.05, mat="pants_dark", pos=[0.13, 0.65, 0], rot=[-3,0,0], skin="rig")
  rounded_box "shin_r" (size=[0.14, 0.40, 0.14], radius=0.04, mat="pants_dark", pos=[0.13, 0.20, 0.05], skin="rig")
  rounded_box "foot_r" (size=[0.16, 0.10, 0.30], radius=0.03, mat="boots_dark", pos=[0.13, 0.00, 0.18], skin="rig")
  // Blood stains (clothing)
  box "blood_chest" (size=[0.15, 0.10, 0.02], mat="blood_dark", pos=[-0.05, 1.20, 0.24], skin="rig")
  box "blood_arm" (size=[0.10, 0.05, 0.02], mat="blood_dark", pos=[0.30, 1.30, 0.18], skin="rig")
}
''')

# ============================================================
# walker_zombie_female — female zombie, longer hair, dress
# ============================================================
w("characters", "walker_zombie_female", '''// walker_zombie_female.mog — female walker zombie with long hair and torn dress
meta (name="walker_zombie_female", description="Female walker zombie with long matted hair, torn floral dress, hunched posture", tags=["character","zombie","walker","female","enemy","tier1"], mogen_version="0.1.12")
material "skin_pale" (color=[0.60,0.55,0.50], roughness=0.85)
material "hair_long" (color=[0.18,0.14,0.10], roughness=0.85)
material "dress_torn" (color=[0.50,0.40,0.45], roughness=0.85, uv_mode="tile", uv_scale=2.0)
material "boots_dark" (color=[0.10,0.08,0.06], roughness=0.6)
material "eyes_red" (color=[0.85,0.10,0.05], roughness=0.30, emissive=[0.7,0.10,0.05], emissive_strength=0.6)
material "blood_dark" (color=[0.30,0.05,0.05], roughness=0.95)
material "teeth_yellow" (color=[0.65,0.55,0.30], roughness=0.70)
scene {
  skeleton "rig" {
    bone "hips" (pos=[0, 0.95, 0], envelope=0.30) {
      bone "spine" (pos=[0, 0.20, 0.08], envelope=0.35) {
        bone "chest" (pos=[0, 0.22, 0.04], envelope=0.35) {
          bone "neck" (pos=[0, 0.10, -0.04], envelope=0.15) {
            bone "head" (pos=[0, 0.10, -0.02], envelope=0.20)
          }
          bone "shoulder_l" (pos=[-0.22, 0.05, 0], envelope=0.15) {
            bone "upper_arm_l" (pos=[0, -0.20, 0], envelope=0.12) {
              bone "forearm_l" (pos=[0.05, -0.25, 0], envelope=0.12)
            }
          }
          bone "shoulder_r" (pos=[ 0.22, 0.05, 0], envelope=0.15) {
            bone "upper_arm_r" (pos=[0, -0.20, 0], envelope=0.12) {
              bone "forearm_r" (pos=[-0.05, -0.25, 0], envelope=0.12)
            }
          }
        }
      }
      bone "thigh_l" (pos=[-0.12, -0.05, 0], envelope=0.25) {
        bone "shin_l" (pos=[0, -0.45, 0], envelope=0.22) {
          bone "foot_l" (pos=[0, -0.42, 0.05], envelope=0.12)
        }
      }
      bone "thigh_r" (pos=[ 0.12, -0.05, 0], envelope=0.25) {
        bone "shin_r" (pos=[0, -0.45, 0], envelope=0.22) {
          bone "foot_r" (pos=[0, -0.42, 0.05], envelope=0.12)
        }
      }
    }
  }
  // Body — slimmer female proportions
  rounded_box "pelvis_mesh" (size=[0.30, 0.18, 0.22], radius=0.04, mat="dress_torn", pos=[0, 0.90, 0.04], skin="rig")
  rounded_box "torso_mesh" (size=[0.40, 0.50, 0.26], radius=0.05, mat="dress_torn", pos=[0, 1.18, 0.08], skin="rig")
  // Dress extends below hips
  cone "dress_skirt" (radius=0.28, height=0.50, mat="dress_torn", pos=[0, 0.65, 0.04], skin="rig")
  rounded_box "head_mesh" (size=[0.20, 0.24, 0.20], radius=0.04, mat="skin_pale", pos=[0, 1.50, 0.02], skin="rig")
  // Long hair — covering sides and back of head
  box "hair_top" (size=[0.22, 0.08, 0.22], mat="hair_long", pos=[0, 1.60, 0.02], skin="rig")
  box "hair_back" (size=[0.22, 0.30, 0.06], mat="hair_long", pos=[0, 1.45, -0.10], skin="rig")
  box "hair_l" (size=[0.06, 0.25, 0.18], mat="hair_long", pos=[-0.11, 1.40, 0.02], skin="rig")
  box "hair_r" (size=[0.06, 0.25, 0.18], mat="hair_long", pos=[0.11, 1.40, 0.02], skin="rig")
  // Eyes — glowing red
  sphere "eye_l" (radius=0.022, mat="eyes_red", pos=[-0.045, 1.51, 0.12], skin="rig")
  sphere "eye_r" (radius=0.022, mat="eyes_red", pos=[0.045, 1.51, 0.12], skin="rig")
  // Mouth
  box "mouth_open" (size=[0.10, 0.05, 0.04], mat="blood_dark", pos=[0, 1.42, 0.12], skin="rig")
  box "teeth_top" (size=[0.08, 0.02, 0.02], mat="teeth_yellow", pos=[0, 1.44, 0.11], skin="rig")
  // Arms — reaching forward
  rounded_box "upper_arm_l" (size=[0.12, 0.30, 0.12], radius=0.04, mat="dress_torn", pos=[-0.28, 1.18, 0.20], rot=[70,0,0], skin="rig")
  rounded_box "forearm_l" (size=[0.10, 0.30, 0.10], radius=0.04, mat="skin_pale", pos=[-0.28, 1.00, 0.45], rot=[70,0,0], skin="rig")
  rounded_box "hand_l" (size=[0.08, 0.10, 0.06], radius=0.03, mat="skin_pale", pos=[-0.28, 0.88, 0.65], skin="rig")
  rounded_box "upper_arm_r" (size=[0.12, 0.30, 0.12], radius=0.04, mat="dress_torn", pos=[0.28, 1.18, 0.20], rot=[70,0,0], skin="rig")
  rounded_box "forearm_r" (size=[0.10, 0.30, 0.10], radius=0.04, mat="skin_pale", pos=[0.28, 1.00, 0.45], rot=[70,0,0], skin="rig")
  rounded_box "hand_r" (size=[0.08, 0.10, 0.06], radius=0.03, mat="skin_pale", pos=[0.28, 0.88, 0.65], skin="rig")
  // Legs
  rounded_box "thigh_l" (size=[0.14, 0.45, 0.14], radius=0.05, mat="skin_pale", pos=[-0.12, 0.65, 0.04], skin="rig")
  rounded_box "shin_l" (size=[0.12, 0.40, 0.12], radius=0.04, mat="skin_pale", pos=[-0.12, 0.20, 0.04], skin="rig")
  rounded_box "foot_l" (size=[0.14, 0.10, 0.28], radius=0.03, mat="boots_dark", pos=[-0.12, 0.00, 0.14], skin="rig")
  rounded_box "thigh_r" (size=[0.14, 0.45, 0.14], radius=0.05, mat="skin_pale", pos=[0.12, 0.65, 0.04], skin="rig")
  rounded_box "shin_r" (size=[0.12, 0.40, 0.12], radius=0.04, mat="skin_pale", pos=[0.12, 0.20, 0.04], skin="rig")
  rounded_box "foot_r" (size=[0.14, 0.10, 0.28], radius=0.03, mat="boots_dark", pos=[0.12, 0.00, 0.14], skin="rig")
  // Blood stains
  box "blood_shoulder" (size=[0.10, 0.06, 0.02], mat="blood_dark", pos=[0.22, 1.30, 0.18], skin="rig")
  box "blood_mouth_chin" (size=[0.06, 0.04, 0.02], mat="blood_dark", pos=[0, 1.38, 0.13], skin="rig")
}
''')

# ============================================================
# crawler_zombie — legless, dragging on ground
# ============================================================
w("characters", "crawler_zombie", '''// crawler_zombie.mog — legless crawler zombie dragging torso with arms
meta (name="crawler_zombie", description="Legless crawler zombie — drags itself forward with arms, torso on ground", tags=["character","zombie","crawler","enemy","tier1"], mogen_version="0.1.12")
material "skin_zombie" (color=[0.45,0.50,0.40], roughness=0.85)
material "shirt_ragged" (color=[0.30,0.25,0.20], roughness=0.85, uv_mode="tile", uv_scale=2.0)
material "pants_torn" (color=[0.15,0.13,0.10], roughness=0.85)
material "hair_dark" (color=[0.12,0.10,0.08], roughness=0.80)
material "eyes_red" (color=[0.85,0.10,0.05], roughness=0.30, emissive=[0.7,0.10,0.05], emissive_strength=0.6)
material "blood_dark" (color=[0.30,0.05,0.05], roughness=0.95)
material "teeth_yellow" (color=[0.65,0.55,0.30], roughness=0.70)
material "ground_dark" (color=[0.20,0.18,0.15], roughness=0.95)
scene {
  // Ground patch (small)
  slab "ground" (size=[3.0, 0.04, 3.0], mat="ground_dark", pos=[0, 0.02, 0], tags="floating")
  skeleton "rig" {
    bone "hips" (pos=[0, 0.20, 0], envelope=0.30) {
      bone "spine" (pos=[0, 0.15, 0.10], envelope=0.35) {
        bone "chest" (pos=[0, 0.20, 0.15], envelope=0.35) {
          bone "neck" (pos=[0, 0.10, 0.05], envelope=0.15) {
            bone "head" (pos=[0, 0.10, 0.10], envelope=0.20)
          }
          bone "shoulder_l" (pos=[-0.22, 0.05, 0], envelope=0.15) {
            bone "upper_arm_l" (pos=[0, -0.15, 0.20], envelope=0.12) {
              bone "forearm_l" (pos=[0, -0.10, 0.30], envelope=0.12)
            }
          }
          bone "shoulder_r" (pos=[ 0.22, 0.05, 0], envelope=0.15) {
            bone "upper_arm_r" (pos=[0, -0.15, 0.20], envelope=0.12) {
              bone "forearm_r" (pos=[0, -0.10, 0.30], envelope=0.12)
            }
          }
        }
      }
    }
  }
  // Torso lying on ground
  rounded_box "pelvis_mesh" (size=[0.32, 0.18, 0.22], radius=0.04, mat="pants_torn", pos=[0, 0.18, 0], skin="rig")
  rounded_box "torso_mesh" (size=[0.45, 0.30, 0.28], radius=0.05, mat="shirt_ragged", pos=[0, 0.30, 0.20], skin="rig")
  rounded_box "head_mesh" (size=[0.22, 0.26, 0.22], radius=0.04, mat="skin_zombie", pos=[0, 0.40, 0.55], skin="rig")
  // Hair
  box "hair_mesh" (size=[0.24, 0.06, 0.24], mat="hair_dark", pos=[0, 0.51, 0.55], skin="rig")
  // Eyes — looking forward
  sphere "eye_l" (radius=0.025, mat="eyes_red", pos=[-0.05, 0.40, 0.66], skin="rig")
  sphere "eye_r" (radius=0.025, mat="eyes_red", pos=[0.05, 0.40, 0.66], skin="rig")
  // Mouth — snarling, blood-covered
  box "mouth_open" (size=[0.12, 0.06, 0.04], mat="blood_dark", pos=[0, 0.32, 0.66], skin="rig")
  box "teeth_top" (size=[0.10, 0.02, 0.02], mat="teeth_yellow", pos=[0, 0.34, 0.65], skin="rig")
  // Arms — reaching forward
  rounded_box "upper_arm_l" (size=[0.14, 0.20, 0.14], radius=0.04, mat="shirt_ragged", pos=[-0.28, 0.30, 0.40], rot=[80,0,0], skin="rig")
  rounded_box "forearm_l" (size=[0.12, 0.20, 0.12], radius=0.04, mat="skin_zombie", pos=[-0.28, 0.20, 0.65], rot=[80,0,0], skin="rig")
  rounded_box "hand_l" (size=[0.10, 0.08, 0.14], radius=0.03, mat="skin_zombie", pos=[-0.28, 0.10, 0.85], skin="rig")
  rounded_box "upper_arm_r" (size=[0.14, 0.20, 0.14], radius=0.04, mat="shirt_ragged", pos=[0.28, 0.30, 0.40], rot=[80,0,0], skin="rig")
  rounded_box "forearm_r" (size=[0.12, 0.20, 0.12], radius=0.04, mat="skin_zombie", pos=[0.28, 0.20, 0.65], rot=[80,0,0], skin="rig")
  rounded_box "hand_r" (size=[0.10, 0.08, 0.14], radius=0.03, mat="skin_zombie", pos=[0.28, 0.10, 0.85], skin="rig")
  // Severed legs — just stumps with blood
  rounded_box "leg_stump_l" (size=[0.18, 0.18, 0.18], radius=0.05, mat="pants_torn", pos=[-0.13, 0.18, -0.10], skin="rig")
  rounded_box "leg_stump_r" (size=[0.18, 0.18, 0.18], radius=0.05, mat="pants_torn", pos=[0.13, 0.18, -0.10], skin="rig")
  // Blood trail behind
  box "blood_trail_1" (size=[0.40, 0.04, 0.40], mat="blood_dark", pos=[0, 0.04, -0.30], tags="floating")
  box "blood_trail_2" (size=[0.30, 0.04, 0.50], mat="blood_dark", pos=[0, 0.04, -0.70], tags="floating")
  // Blood on torso
  box "blood_torso" (size=[0.20, 0.10, 0.02], mat="blood_dark", pos=[0, 0.30, 0.34], skin="rig")
}
''')

# ============================================================
# npc_survivor — civilian survivor with backpack
# ============================================================
w("characters", "npc_survivor", '''// npc_survivor.mog — civilian survivor with backpack and bat
meta (name="npc_survivor", description="Civilian survivor with backpack, holding baseball bat, alert pose", tags=["character","npc","survivor","neutral","tier1"], mogen_version="0.1.12")
material "skin" (color=[0.86,0.70,0.56], roughness=0.7)
material "hair_brown" (color=[0.30,0.20,0.12], roughness=0.80)
material "jacket_green" (color=[0.30,0.40,0.25], roughness=0.80, uv_mode="tile", uv_scale=3.0)
material "pants_jeans" (color=[0.20,0.25,0.40], roughness=0.85)
material "boots_brown" (color=[0.25,0.18,0.10], roughness=0.6)
material "backpack_dark" (color=[0.20,0.20,0.22], roughness=0.85)
material "bat_wood" (color=[0.55,0.40,0.25], roughness=0.85)
material "eyes_white" (color=[0.95,0.95,0.95], roughness=0.30, emissive=[0.10,0.10,0.10], emissive_strength=0.3)
material "strap_black" (color=[0.10,0.10,0.12], roughness=0.80)
scene {
  skeleton "rig" {
    bone "hips" (pos=[0, 0.95, 0], envelope=0.30) {
      bone "spine" (pos=[0, 0.25, 0], envelope=0.35) {
        bone "chest" (pos=[0, 0.25, 0], envelope=0.35) {
          bone "neck" (pos=[0, 0.10, 0], envelope=0.15) {
            bone "head" (pos=[0, 0.10, 0], envelope=0.20)
          }
          bone "shoulder_l" (pos=[-0.22, 0.05, 0], envelope=0.15) {
            bone "upper_arm_l" (pos=[0, -0.20, 0], envelope=0.12) {
              bone "forearm_l" (pos=[0, -0.25, 0], envelope=0.12)
            }
          }
          bone "shoulder_r" (pos=[ 0.22, 0.05, 0], envelope=0.15) {
            bone "upper_arm_r" (pos=[0, -0.20, 0], envelope=0.12) {
              bone "forearm_r" (pos=[0, -0.25, 0], envelope=0.12)
            }
          }
        }
      }
      bone "thigh_l" (pos=[-0.11, -0.05, 0], envelope=0.25) {
        bone "shin_l" (pos=[0, -0.45, 0], envelope=0.22) {
          bone "foot_l" (pos=[0, -0.42, 0.05], envelope=0.12)
        }
      }
      bone "thigh_r" (pos=[ 0.11, -0.05, 0], envelope=0.25) {
        bone "shin_r" (pos=[0, -0.45, 0], envelope=0.22) {
          bone "foot_r" (pos=[0, -0.42, 0.05], envelope=0.12)
        }
      }
    }
  }
  // Body — upright alert pose
  rounded_box "pelvis_mesh" (size=[0.32, 0.20, 0.22], radius=0.04, mat="pants_jeans", pos=[0, 0.95, 0], skin="rig")
  rounded_box "torso_mesh" (size=[0.45, 0.55, 0.28], radius=0.05, mat="jacket_green", pos=[0, 1.30, 0], skin="rig")
  rounded_box "head_mesh" (size=[0.22, 0.26, 0.22], radius=0.04, mat="skin", pos=[0, 1.65, 0], skin="rig")
  // Hair — short
  box "hair_mesh" (size=[0.24, 0.08, 0.24], mat="hair_brown", pos=[0, 1.78, 0], skin="rig")
  // Eyes — looking forward, alert
  sphere "eye_l" (radius=0.025, mat="eyes_white", pos=[-0.05, 1.66, 0.115], skin="rig")
  sphere "eye_r" (radius=0.025, mat="eyes_white", pos=[0.05, 1.66, 0.115], skin="rig")
  // Mouth — closed, neutral
  box "mouth" (size=[0.08, 0.015, 0.02], mat="strap_black", pos=[0, 1.56, 0.115], skin="rig")
  // Arms — right arm raised holding bat
  rounded_box "upper_arm_l" (size=[0.14, 0.25, 0.14], radius=0.04, mat="jacket_green", pos=[-0.28, 1.25, 0], skin="rig")
  rounded_box "forearm_l" (size=[0.12, 0.25, 0.12], radius=0.04, mat="skin", pos=[-0.28, 0.95, 0], skin="rig")
  rounded_box "hand_l" (size=[0.10, 0.10, 0.06], radius=0.03, mat="skin", pos=[-0.28, 0.80, 0], skin="rig")
  // Right arm — raised, holding bat
  rounded_box "upper_arm_r" (size=[0.14, 0.25, 0.14], radius=0.04, mat="jacket_green", pos=[0.30, 1.55, 0], rot=[0,0,-60], skin="rig")
  rounded_box "forearm_r" (size=[0.12, 0.25, 0.12], radius=0.04, mat="skin", pos=[0.55, 1.50, 0], skin="rig")
  rounded_box "hand_r" (size=[0.10, 0.10, 0.06], radius=0.03, mat="skin", pos=[0.65, 1.30, 0], skin="rig")
  // Baseball bat (in right hand, pointing up)
  cylinder "bat" (radius=0.04, height=0.85, mat="bat_wood", pos=[0.70, 1.30, 0], rot=[0,0,0], skin="rig")
  cylinder "bat_handle" (radius=0.03, height=0.20, mat="strap_black", pos=[0.70, 0.95, 0], skin="rig")
  // Legs — standing
  rounded_box "thigh_l" (size=[0.16, 0.45, 0.16], radius=0.05, mat="pants_jeans", pos=[-0.12, 0.65, 0], skin="rig")
  rounded_box "shin_l" (size=[0.14, 0.40, 0.14], radius=0.04, mat="pants_jeans", pos=[-0.12, 0.20, 0], skin="rig")
  rounded_box "foot_l" (size=[0.16, 0.10, 0.30], radius=0.03, mat="boots_brown", pos=[-0.12, 0.00, 0.10], skin="rig")
  rounded_box "thigh_r" (size=[0.16, 0.45, 0.16], radius=0.05, mat="pants_jeans", pos=[0.12, 0.65, 0], skin="rig")
  rounded_box "shin_r" (size=[0.14, 0.40, 0.14], radius=0.04, mat="pants_jeans", pos=[0.12, 0.20, 0], skin="rig")
  rounded_box "foot_r" (size=[0.16, 0.10, 0.30], radius=0.03, mat="boots_brown", pos=[0.12, 0.00, 0.10], skin="rig")
  // Backpack — on back
  rounded_box "backpack_body" (size=[0.30, 0.45, 0.18], radius=0.06, mat="backpack_dark", pos=[0, 1.25, -0.20], skin="rig")
  // Backpack straps (over shoulders)
  box "strap_l" (size=[0.05, 0.50, 0.03], mat="strap_black", pos=[-0.15, 1.30, -0.10], skin="rig")
  box "strap_r" (size=[0.05, 0.50, 0.03], mat="strap_black", pos=[0.15, 1.30, -0.10], skin="rig")
  // Bedroll on top of backpack
  cylinder "bedroll" (radius=0.08, height=0.35, mat="jacket_green", pos=[0, 1.55, -0.20], rot=[0,90,0], skin="rig")
  // Canteen on hip (left side)
  cylinder "canteen" (radius=0.06, height=0.15, mat="jacket_green", pos=[-0.20, 0.95, 0.10], rot=[90,0,0], skin="rig")
}
''')

# ============================================================
# npc_soldier — military soldier with rifle
# ============================================================
w("characters", "npc_soldier", '''// npc_soldier.mog — military soldier with assault rifle
meta (name="npc_soldier", description="Military soldier in tactical gear holding assault rifle, combat-ready pose", tags=["character","npc","soldier","military","neutral","tier1"], mogen_version="0.1.12")
material "skin" (color=[0.80,0.65,0.50], roughness=0.7)
material "helmet_olive" (color=[0.30,0.32,0.20], roughness=0.60, metallic=0.3)
material "uniform_olive" (color=[0.32,0.35,0.22], roughness=0.80, uv_mode="tile", uv_scale=3.0)
material "vest_olive" (color=[0.25,0.28,0.18], roughness=0.70, metallic=0.3)
material "boots_black" (color=[0.05,0.05,0.06], roughness=0.6)
material "rifle_black" (color=[0.10,0.10,0.12], roughness=0.40, metallic=0.85)
material "metal_grey" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.85)
material "eyes_white" (color=[0.95,0.95,0.95], roughness=0.30, emissive=[0.10,0.10,0.10], emissive_strength=0.3)
material "strap_black" (color=[0.10,0.10,0.12], roughness=0.80)
scene {
  skeleton "rig" {
    bone "hips" (pos=[0, 0.95, 0], envelope=0.30) {
      bone "spine" (pos=[0, 0.25, 0], envelope=0.35) {
        bone "chest" (pos=[0, 0.25, 0], envelope=0.35) {
          bone "neck" (pos=[0, 0.10, 0], envelope=0.15) {
            bone "head" (pos=[0, 0.10, 0], envelope=0.20)
          }
          bone "shoulder_l" (pos=[-0.22, 0.05, 0], envelope=0.15) {
            bone "upper_arm_l" (pos=[0, -0.20, 0], envelope=0.12) {
              bone "forearm_l" (pos=[0, -0.25, 0], envelope=0.12)
            }
          }
          bone "shoulder_r" (pos=[ 0.22, 0.05, 0], envelope=0.15) {
            bone "upper_arm_r" (pos=[0, -0.20, 0], envelope=0.12) {
              bone "forearm_r" (pos=[0, -0.25, 0], envelope=0.12)
            }
          }
        }
      }
      bone "thigh_l" (pos=[-0.11, -0.05, 0], envelope=0.25) {
        bone "shin_l" (pos=[0, -0.45, 0], envelope=0.22) {
          bone "foot_l" (pos=[0, -0.42, 0.05], envelope=0.12)
        }
      }
      bone "thigh_r" (pos=[ 0.11, -0.05, 0], envelope=0.25) {
        bone "shin_r" (pos=[0, -0.45, 0], envelope=0.22) {
          bone "foot_r" (pos=[0, -0.42, 0.05], envelope=0.12)
        }
      }
    }
  }
  // Body — combat stance, slightly crouched
  rounded_box "pelvis_mesh" (size=[0.34, 0.20, 0.22], radius=0.04, mat="uniform_olive", pos=[0, 0.90, 0], skin="rig")
  rounded_box "torso_mesh" (size=[0.48, 0.55, 0.30], radius=0.05, mat="uniform_olive", pos=[0, 1.25, 0], skin="rig")
  // Tactical vest (over torso)
  rounded_box "vest_mesh" (size=[0.50, 0.45, 0.32], radius=0.04, mat="vest_olive", pos=[0, 1.30, 0], skin="rig")
  // Vest pouches (front)
  box "pouch_l" (size=[0.12, 0.15, 0.05], mat="vest_olive", pos=[-0.13, 1.20, 0.17], skin="rig")
  box "pouch_r" (size=[0.12, 0.15, 0.05], mat="vest_olive", pos=[0.13, 1.20, 0.17], skin="rig")
  // Head + helmet
  rounded_box "head_mesh" (size=[0.22, 0.26, 0.22], radius=0.04, mat="skin", pos=[0, 1.60, 0], skin="rig")
  // Helmet (covers top half of head)
  box "helmet_top" (size=[0.26, 0.14, 0.28], mat="helmet_olive", pos=[0, 1.72, 0], skin="rig")
  box "helmet_rim" (size=[0.28, 0.04, 0.30], mat="helmet_olive", pos=[0, 1.66, 0], skin="rig")
  // Helmet strap
  box "strap_chin" (size=[0.04, 0.10, 0.04], mat="strap_black", pos=[0, 1.55, 0.13], skin="rig")
  // Eyes
  sphere "eye_l" (radius=0.025, mat="eyes_white", pos=[-0.05, 1.62, 0.115], skin="rig")
  sphere "eye_r" (radius=0.025, mat="eyes_white", pos=[0.05, 1.62, 0.115], skin="rig")
  // Arms — both forward, holding rifle
  rounded_box "upper_arm_l" (size=[0.14, 0.25, 0.14], radius=0.04, mat="uniform_olive", pos=[-0.28, 1.30, 0.15], rot=[60,0,0], skin="rig")
  rounded_box "forearm_l" (size=[0.12, 0.25, 0.12], radius=0.04, mat="uniform_olive", pos=[-0.28, 1.10, 0.40], rot=[60,0,0], skin="rig")
  rounded_box "hand_l" (size=[0.10, 0.10, 0.06], radius=0.03, mat="skin", pos=[-0.28, 1.00, 0.60], skin="rig")
  rounded_box "upper_arm_r" (size=[0.14, 0.25, 0.14], radius=0.04, mat="uniform_olive", pos=[0.28, 1.30, 0.15], rot=[60,0,0], skin="rig")
  rounded_box "forearm_r" (size=[0.12, 0.25, 0.12], radius=0.04, mat="uniform_olive", pos=[0.28, 1.10, 0.40], rot=[60,0,0], skin="rig")
  rounded_box "hand_r" (size=[0.10, 0.10, 0.06], radius=0.03, mat="skin", pos=[0.28, 1.00, 0.60], skin="rig")
  // Rifle (held in both hands, pointing forward)
  box "rifle_body" (size=[0.08, 0.12, 0.80], mat="rifle_black", pos=[0, 1.05, 0.50], skin="rig")
  box "rifle_barrel" (size=[0.04, 0.04, 0.40], mat="rifle_black", pos=[0, 1.10, 0.95], skin="rig")
  box "rifle_magazine" (size=[0.06, 0.18, 0.10], mat="rifle_black", pos=[0, 0.92, 0.45], skin="rig")
  box "rifle_stock" (size=[0.08, 0.15, 0.20], mat="rifle_black", pos=[0, 1.05, 0.20], skin="rig")
  box "rifle_scope" (size=[0.05, 0.10, 0.20], mat="metal_grey", pos=[0, 1.18, 0.55], skin="rig")
  // Legs — slightly bent (combat stance)
  rounded_box "thigh_l" (size=[0.18, 0.42, 0.16], radius=0.05, mat="uniform_olive", pos=[-0.13, 0.65, 0.05], rot=[10,0,0], skin="rig")
  rounded_box "shin_l" (size=[0.16, 0.40, 0.14], radius=0.04, mat="uniform_olive", pos=[-0.13, 0.25, 0.12], skin="rig")
  rounded_box "foot_l" (size=[0.18, 0.10, 0.32], radius=0.03, mat="boots_black", pos=[-0.13, 0.00, 0.22], skin="rig")
  rounded_box "thigh_r" (size=[0.18, 0.42, 0.16], radius=0.05, mat="uniform_olive", pos=[0.13, 0.65, 0.05], rot=[10,0,0], skin="rig")
  rounded_box "shin_r" (size=[0.16, 0.40, 0.14], radius=0.04, mat="uniform_olive", pos=[0.13, 0.25, 0.12], skin="rig")
  rounded_box "foot_r" (size=[0.18, 0.10, 0.32], radius=0.03, mat="boots_black", pos=[0.13, 0.00, 0.22], skin="rig")
  // Knee pads
  box "knee_pad_l" (size=[0.18, 0.10, 0.04], mat="vest_olive", pos=[-0.13, 0.30, 0.16], skin="rig")
  box "knee_pad_r" (size=[0.18, 0.10, 0.04], mat="vest_olive", pos=[0.13, 0.30, 0.16], skin="rig")
  // Backpack (small assault pack)
  rounded_box "pack_body" (size=[0.30, 0.40, 0.18], radius=0.05, mat="vest_olive", pos=[0, 1.25, -0.18], skin="rig")
  // Antenna on pack
  cylinder "antenna" (radius=0.01, height=0.50, mat="metal_grey", pos=[0.15, 1.70, -0.18], skin="rig")
}
''')

print("\n=== Part C: 5 characters written ===")
