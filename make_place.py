from pathlib import Path
import uuid
import math
import random
import xml.sax.saxutils as saxutils

ROOT = Path(__file__).parent

def ref():
    return 'RBX' + uuid.uuid4().hex.upper()

def instance(class_name, name, children=''):
    safe_name = saxutils.escape(name)
    return f'''<Item class="{class_name}" referent="{ref()}">
  <Properties><string name="Name">{safe_name}</string></Properties>
  {children}
</Item>'''

def script_instance(class_name, name, source):
    if ']]>' in source:
        raise ValueError(f'CDATA terminator found in {name}')
    safe_name = saxutils.escape(name)
    disabled = '<bool name="Disabled">false</bool>'
    run_context = '<token name="RunContext">1</token>' if class_name == 'Script' else ''
    return f'''<Item class="{class_name}" referent="{ref()}">
  <Properties>
    {disabled}
    <string name="Name">{safe_name}</string>
    {run_context}
    <ProtectedString name="Source"><![CDATA[
{source}
    ]]></ProtectedString>
  </Properties>
</Item>'''

def cframe(x, y, z, rotation=None):
    if rotation is None:
        rotation = (1, 0, 0, 0, 1, 0, 0, 0, 1)
    r00, r01, r02, r10, r11, r12, r20, r21, r22 = rotation
    return f'''<CoordinateFrame name="CFrame"><X>{x}</X><Y>{y}</Y><Z>{z}</Z><R00>{r00}</R00><R01>{r01}</R01><R02>{r02}</R02><R10>{r10}</R10><R11>{r11}</R11><R12>{r12}</R12><R20>{r20}</R20><R21>{r21}</R21><R22>{r22}</R22></CoordinateFrame>'''

def vector3(tag, name, x, y, z):
    return f'<Vector3 name="{name}"><X>{x}</X><Y>{y}</Y><Z>{z}</Z></Vector3>'

def color3(name, rgb):
    vals = [v / 255 for v in rgb]
    return f'<Color3 name="{name}"><R>{vals[0]:.8f}</R><G>{vals[1]:.8f}</G><B>{vals[2]:.8f}</B></Color3>'

def part_item(name, size, position, rgb, material_token, anchored=True, can_collide=True, class_name='Part', extras='', rotation=None, shape_token=None):
    props = [
        f'<bool name="Anchored">{str(anchored).lower()}</bool>',
        f'<bool name="CanCollide">{str(can_collide).lower()}</bool>',
        f'<bool name="CanQuery">true</bool>',
        f'<bool name="CanTouch">true</bool>',
        cframe(*position, rotation=rotation),
        color3('Color', rgb),
        f'<string name="Name">{saxutils.escape(name)}</string>',
        f'<token name="Material">{material_token}</token>',
        vector3('Vector3', 'Size', *size),
    ]
    if shape_token is not None:
        props.append(f'<token name="Shape">{shape_token}</token>')
    if extras:
        props.extend(extras.split('\n'))
    props.sort(key=lambda item: item.split(' name="', 1)[-1].split('"', 1)[0] if ' name="' in item else '')
    body = '\n    '.join(props)
    return f'''<Item class="{class_name}" referent="{ref()}">
  <Properties>
    {body}
  </Properties>
</Item>'''

def startup_preview():
    """Serialize a full static map preview so the place is not empty in edit mode.

    The live server script creates the interactive version of this map and removes
    this preview once its real spawn and garage are ready. Preview geometry sits
    slightly below the live geometry to avoid z-fighting during startup.
    """
    parts = []

    def add(name, size, pos, rgb, material, collide=True, rotation=None, shape=None):
        parts.append(part_item(name, size, pos, rgb, material, can_collide=collide, rotation=rotation, shape_token=shape))

    grass = (81, 123, 91)
    ocean = (38, 117, 151)
    asphalt = (43, 48, 57)
    white = (220, 225, 225)
    amber = (255, 190, 76)
    mint = (66, 238, 220)
    dark_metal = (37, 53, 69)
    # Under-island water and green island, with the main ground top at -0.1.
    add('PreviewCoastalWater', (1800, 8, 1800), (0, -8, 0), ocean, 1568)
    add('PreviewIslandGround', (820, 8, 820), (0, -4.1, 0), grass, 1280)
    for name, size, pos in [
        ('PreviewCliffNorth', (820, 18, 10), (0, 5, -405)),
        ('PreviewCliffSouth', (820, 18, 10), (0, 5, 405)),
        ('PreviewCliffEast', (10, 18, 820), (405, 5, 0)),
        ('PreviewCliffWest', (10, 18, 820), (-405, 5, 0)),
    ]:
        add(name, size, pos, (93, 104, 92), 896)

    def look_rotation(dx, dz):
        length = math.sqrt(dx * dx + dz * dz)
        if length < 1e-6:
            return (1, 0, 0, 0, 1, 0, 0, 0, 1)
        dir_x, dir_z = dx / length, dz / length
        right_x, right_z = -dir_z, dir_x
        back_x, back_z = -dir_x, -dir_z
        return (right_x, 0, back_x, 0, 1, 0, right_z, 0, back_z)

    def local_to_world(mid, rotation, lx, ly, lz):
        r00, _, r02, _, _, _, r20, _, r22 = rotation
        return (mid[0] + r00 * lx + r02 * lz, mid[1] + ly, mid[2] + r20 * lx + r22 * lz)

    def road_segment(start, finish, width, name):
        ax, az = start
        bx, bz = finish
        dx, dz = bx - ax, bz - az
        length = math.sqrt(dx * dx + dz * dz)
        mid = ((ax + bx) / 2, -0.075, (az + bz) / 2)  # top at 0.2, just under live road
        rot = look_rotation(dx, dz)
        add(name, (width, 0.55, length + 5), mid, asphalt, 1376, rotation=rot)
        for side in (-1, 1):
            stripe_pos = local_to_world(mid, rot, side * (width / 2 - 1.6), 0.305, 0)
            add('PreviewRoadEdge', (0.32, 0.055, length), stripe_pos, white, 272, False, rot)
        offset = -length / 2 + 8
        dash_index = 0
        while offset < length / 2 - 3:
            dash_index += 1
            dash_pos = local_to_world(mid, rot, 0, 0.31, offset)
            add('PreviewCenterLine', (0.45, 0.06, 7), dash_pos, amber, 288, False, rot)
            offset += 19
        # Streetlights on longer straight segments.
        if length > 100:
            for fraction in (0.28, 0.72):
                x, z = ax + dx * fraction, az + dz * fraction
                add('PreviewStreetLampPole', (0.55, 10, 0.55), (x, 5, z), dark_metal, 1088)
                add('PreviewStreetLampHead', (2.2, 0.55, 1.2), (x, 10.2, z), (255, 210, 145), 288, False)

    route = [(-220, 70), (-220, -130), (-120, -250), (80, -250), (230, -140), (230, 60), (120, 220), (-100, 220)]
    for i in range(len(route)):
        road_segment(route[i], route[(i + 1) % len(route)], 40, f'PreviewCoastalRoad_{i+1}')
    road_segment((-300, 120), (-220, 120), 32, 'PreviewGarageLink')
    road_segment((-220, 120), (-220, 70), 32, 'PreviewGarageApproach')

    rng = random.Random(74421)
    building_colors = [(45, 67, 86), (60, 75, 89), (68, 78, 102), (82, 91, 104), (48, 81, 89)]
    accents = [(66, 238, 220), (255, 174, 92), (115, 162, 255), (214, 130, 255)]
    building_coords = [(-100, -95), (-35, -95), (35, -95), (100, -95),
                       (-100, -30), (-35, -30), (35, -30), (100, -30),
                       (-100, 35), (-35, 35), (35, 35), (100, 35),
                       (-100, 100), (-35, 100), (35, 100), (100, 100)]
    for i, (x, z) in enumerate(building_coords, start=1):
        width, depth, height = rng.randint(20, 27), rng.randint(20, 27), rng.randint(28, 82)
        base_color, accent = rng.choice(building_colors), rng.choice(accents)
        add(f'PreviewCityBuilding_{i}', (width, height, depth), (x, height / 2 - 0.1, z), base_color, 816)
        add('PreviewRoofTrim', (width + 1, 0.6, depth + 1), (x, height + 0.15, z), accent, 288, False)
        add('PreviewFacadeAccent', (0.7, height - 4, 0.35), (x - width / 2 + 2, height / 2 - 0.1, z - depth / 2 - 0.2), accent, 288, False)
        floor_y = 8
        while floor_y < height - 4:
            add('PreviewGlassBand', (width - 5, 2.3, 0.22), (x, floor_y, z - depth / 2 - 0.18), (105, 178, 204), 1568, False)
            floor_y += 10

    add('PreviewHarborBeacon', (10, 115, 10), (0, 57.4, 0), dark_metal, 1088)
    add('PreviewBeaconLight', (15, 2, 15), (0, 115.9, 0), mint, 288, False)

    tree_positions = [(-345, -330), (-285, -348), (-210, -352), (-120, -350), (-20, -350),
        (85, -350), (180, -350), (280, -338), (345, -280), (350, -170), (350, -60),
        (350, 55), (345, 165), (320, 280), (230, 345), (120, 350), (10, 350),
        (-100, 350), (-210, 345), (-320, 280), (-350, 165), (-350, 40), (-350, -90)]
    for x, z in tree_positions:
        trunk_height = rng.randint(7, 11)
        add('PreviewPineTrunk', (2.2, trunk_height, 2.2), (x, trunk_height / 2, z), (108, 79, 55), 512)
        canopy_color = (42, rng.randint(105, 138), 94)
        add('PreviewPineCanopyLower', (10, 7, 10), (x, trunk_height + 1.5, z), canopy_color, 1280, True)
        add('PreviewPineCanopyUpper', (7, 6, 7), (x, trunk_height + 6.5, z), canopy_color, 1280, True)

    # Garage shell, three car pads, and the two electric-bike display pads.
    add('PreviewGarageFloor', (46, 0.7, 76), (-304, -0.05, 120), (47, 56, 68), 816)
    add('PreviewGarageBackWall', (1.2, 17, 76), (-338, 8.1, 120), (35, 46, 59), 1088)
    add('PreviewGarageRoof', (46, 1.5, 76), (-316, 17.1, 120), (27, 37, 50), 1088)
    add('PreviewGarageNeonBeam', (1, 1.2, 77), (-293, 15.3, 120), mint, 288, False)
    add('PreviewGarageSign', (0.8, 5, 31), (-292.5, 10.6, 120), (13, 28, 42), 272, False)
    car_accents = [(255, 209, 116), (176, 255, 239), (225, 210, 255)]
    for i, z in enumerate((82, 111, 140)):
        add(f'PreviewCarPad_{i+1}', (16, 0.6, 22), (-286, 0.25, z), (37, 49, 63), 1088)
        add(f'PreviewCarPadGlow_{i+1}', (15, 0.08, 21), (-286, 0.6, z), car_accents[i], 288, False)
    for i, x in enumerate((-232, -222)):
        accent = mint if i == 0 else (75, 185, 255)
        add(f'PreviewEbikePad_{i+1}', (5, 0.35, 5), (x, 0.12, 101), accent, 288)

    # Six visible gates: one start, four cyan checkpoints, and the finish.
    gates = [
        ('Start', (-220, 0.2, 56), (88, 255, 180)),
        ('Checkpoint1', (-220, 0.2, -130), mint),
        ('Checkpoint2', (80, 0.2, -250), mint),
        ('Checkpoint3', (230, 0.2, 60), mint),
        ('Checkpoint4', (-100, 0.2, 220), mint),
        ('Finish', (-160, 0.2, 145), (255, 174, 92)),
    ]
    for gate_name, (x, y, z), accent in gates:
        add(f'PreviewGatePost_{gate_name}_L', (1.4, 10, 1.4), (x - 20, y + 5, z), accent, 288, False)
        add(f'PreviewGatePost_{gate_name}_R', (1.4, 10, 1.4), (x + 20, y + 5, z), accent, 288, False)
        add(f'PreviewGateBeam_{gate_name}', (42, 0.9, 1.5), (x, y + 10, z), accent, 288, False)

    # Static harbor marker so the intended player start is obvious in edit mode.
    add('PreviewHarborSpawnPad', (12, 0.35, 12), (-275, 0.075, 145), mint, 1088)
    return instance('Folder', 'NeonRidgeStartupPreview', '\n'.join(parts))

world_source = (ROOT / 'src/ServerScriptService/NeonRidgeWorld.server.lua').read_text()
physics_source = (ROOT / 'src/ServerScriptService/NeonRidgeVehiclePhysics.server.lua').read_text()
moto_source = (ROOT / 'src/ServerScriptService/NeonRidgeMotoPack.server.lua').read_text()
bootguard_source = (ROOT / 'src/ServerScriptService/NeonRidgeBootGuard.server.lua').read_text()
client_source = (ROOT / 'src/StarterPlayer/StarterPlayerScripts/NeonRidgeClient.client.lua').read_text()

server_children = '\n'.join([
    script_instance('Script', 'NeonRidgeBootGuard', bootguard_source),
    script_instance('Script', 'NeonRidgeWorld', world_source),
    script_instance('Script', 'NeonRidgeVehiclePhysics', physics_source),
    script_instance('Script', 'NeonRidgeMotoPack', moto_source),
])
local_scripts = instance('StarterPlayerScripts', 'StarterPlayerScripts', script_instance('LocalScript', 'NeonRidgeClient', client_source))
starter_player = instance('StarterPlayer', 'StarterPlayer', local_scripts)
server_service = instance('ServerScriptService', 'ServerScriptService', server_children)

# These parts are saved directly in Workspace so Play is safe before server scripts start.
# The main world script removes them after its proper island and spawn are created.
safety_floor = part_item(
    'NeonRidgeSafetyFloor', (860, 8, 860), (0, -4.4, 0), (81, 123, 91), 1280,
)
safety_spawn = part_item(
    'NeonRidgeSafetySpawn', (12, 1, 12), (-275, 0.1, 145), (68, 242, 219), 1088,
    class_name='SpawnLocation',
    extras='<bool name="AllowTeamChangeOnTouch">false</bool>\n<bool name="Neutral">true</bool>\n<float name="Duration">0</float>',
)
workspace = instance('Workspace', 'Workspace', safety_floor + '\n' + safety_spawn + '\n' + startup_preview())

xml = f'''<?xml version="1.0" encoding="utf-8"?>
<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
  <External>null</External>
  <External>nil</External>
  {workspace}
  {server_service}
  {starter_player}
</roblox>
'''
(ROOT / 'NeonRidge_Starter.rbxlx').write_text(xml, encoding='utf-8')
print('Wrote', ROOT / 'NeonRidge_Starter.rbxlx')
