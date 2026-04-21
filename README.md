# Luduvo Binary File Spec

I may have interpreted some of it wrongly, but this information is enough to parse/edit .ldv binaries.

## Contents
- [Luduvo Binary File Spec](#luduvo-binary-file-spec)
  - [Contents](#contents)
  - [File Structure](#file-structure)
  - [File Header](#file-header)
  - [Records](#records)
    - [Record Header](#record-header)
    - [Entry Layout](#entry-layout)
    - [Tag-only entries (for shape components and similar markers):](#tag-only-entries-for-shape-components-and-similar-markers)
    - [Script / ScriptHandle:](#script--scripthandle)
    - [ComponentType Enum](#componenttype-enum)
    - [Material Enum](#material-enum)
  - [Data Types](#data-types)
    - [EntityId](#entityid)
    - [Vec3](#vec3)
    - [Quat](#quat)
    - [Color3](#color3)
    - [String](#string)
  - [Instance stuff](#instance-stuff)
    - [Lighting](#lighting)
    - [PointLight](#pointlight)
    - [SpotLight](#spotlight)
    - [Script / ScriptHandle](#script--scripthandle-1)


## File Structure
Luduvo stores scenes as an ECS snapshot. Entities (in the save file) are identified by 64 bit IDs, and each component (position, color, etc.) is stored as a flat table composed of `entityId -> value` pairs.

Some components, such as the shape components, only store entity id's, as they are used as a tagging system.

Parent/child relationships are expressed through the `ChildOfPairs` component.

The `.ldv` file consists of:

1. A 10 byte File Header
2. A sequence of Records.


## File Header
| Field Name     | Format  | Value                          | Position |
|:---------------|:--------|:-------------------------------|:---------|
| Magic Number   | 4 bytes | Always `LSCN`                  |`0x00`    |
| Version        | `u32`   | Currently `7`                  |`0x04`    |
| Record Count   | `u16`   | Number of records in the file  |`0x08`    |

The records begin immediately after, starting at `0x0A`

## Records

A record holds all entries for a single component type. For example, a `Position` record contains the positions of every entity in the scene that has a `Position` component. In an empty file, there are only two records, Lighting, and the ChildOfPairs.


### Record Header
Each record begins with an 8-byte header:

| Field Name        | Format          | Description                              |
|:------------------|:----------------|:-----------------------------------------|
| Component Type    | `u16` (enum)    | Which component this record describes    |
| Value Size        | `u16`           | Size in bytes of the value per entry     |
| Number of Entries | `u32`           | How many entries follow                  |

Immediately after the header come `Number of Entries` entries.

### Entry Layout

The shape of each entry depends on the component type:

Most entries are like this:

| Field              | Format            | Size |
|:-------------------|:------------------|:-----|
| Entity ID          | `EntityId`        | 8    |
| Value              | *depends on type* | *Value Size* |


### Tag-only entries (for shape components and similar markers):

As mentioned before, if the `Value Size` is `0` and the component is not `Script` or `ScriptHandle`, the record just marks which entities have that component. Each entry is simply an `EntityId` with no value.

| Field     | Format     | Size |
|:----------|:-----------|:-----|
| Entity ID | `EntityId` | 8    |

### Script / ScriptHandle:

`Script` and `ScriptHandle` records will say `ValueSize = 0` in their header despite their entries containing data (??), most likely since they aren't properly implemented yet. Don't worry about them.

### ComponentType Enum

| Name              | Tag      | Value Size | Value Type  | Notes |
|:------------------|:---------|:-----------|:------------|:------|
| Position          | `0x0001` | 12         | `Vec3`      |  |
| Rotation          | `0x0002` | 16         | `Quat`      | Rotation is a quaternion |
| Size              | `0x0003` | 12         | `Vec3`      |  |
| Name              | `0x0004` | 64         | `String`    |  |
| BoxShapeType      | `0x000A` | 0          | *(tag)*     |  |
| SphereShapeType   | `0x000B` | 0          | *(tag)*     |  |
| CylinderShapeType | `0x000C` | 0          | *(tag)*     |  |
| ConeShapeType     | `0x000D` | 0          | *(tag)*     |  |
| WedgeShapeType    | `0x000E` | 0          | *(tag)*     |  |
| PhysicsVec3       | `0x0014` | 12         | `Vec3`      |  |
| Anchored          | `0x0015` | 0          | *(tag)*     | Only spawnParts can be anchored right now |
| UNKNOWN_3         | `0x0016` | ?          | ?           | I only saw this once but haven't figured out what it is lol |
| Color3            | `0x001E` | 12         | `Color3`    |  |
| Transparency      | `0x001F` | 4          | `float`     |  |
| Material          | `0x0020` | 8          | `u64`       | See below for material enum |
| SpawnPoints       | `0x0032` | 0          | *(tag)*     | Marks active spawnpoints probably? |
| NetworkId         | `0x003C` | 8          | `u64`       | |
| ScriptHandle      | `0x0047` | 0 *(see note)* | 15 bytes | undocumented |
| Script            | `0x0048` | 0 *(see note)* | 9 bytes  | undocumented |
| ChildOfPair       | `0x005A` | 8          | `EntityId`  | |
| PointLight        | `0x0064` | 17         | `PointLight`| |
| SpotLight         | `0x0065` | 25         | `SpotLight` | |
| Lighting          | `0x006E` | 29         | `Lighting`  | Always present |

### Material Enum
| Value | Material      |
|:------|:--------------|
| 0     | SmoothPlastic |
| 1     | Plastic       |
| 2     | Brick         |
| 3     | Wood          |
| 4     | Grass         |
| 5     | Ice           |
| 6     | Sand          |
| 7     | Metal         |
| 8     | Aluminum      |
| 9     | Rust          |
| 10    | Neon          |
| 11    | WoodPlanks    |
| 12    | Marble        |
| 13    | Slate         |
| 14    | Concrete      |
| 15    | Granite       |
| 16    | Pebble        |
| 17    | Cobblestone   |
| 18    | DiamondPlate  |
| 19    | Fabric        |

## Data Types

`u8`, `u16`, `u32`, `u64`, and IEEE-754 `float` (32-bit).

Booleans are stored as `u8`: `0` = false, `1` = true.

### EntityId

An 8-byte reference to an entity. Luduvo reuses entity slots, so the generation counter differentiates between entities reassigned with the same recycled id.

| Field              | Format | 
|:-------------------|:-------|
| Entity ID          | `u32`  |
| Entity Generation  | `u32`  | 

### Vec3

| Field | Format  |
|:------|:--------|
| x     | `float` |
| y     | `float` |
| z     | `float` |


### Quat

| Field | Format  |
|:------|:--------|
| x     | `float` |
| y     | `float` |
| z     | `float` |
| w     | `float` |


### Color3

| Field | Format  |
|:------|:--------|
| R     | `float` |
| G     | `float` |
| B     | `float` |


### String

| Field | Format     |
|:------|:-----------|
| text  | `char[64]` |


## Instance stuff

some stuff like Lighting, PointLights, and SpotLights just store their
data all in one struct.

### Lighting

Global Lighting Service. This is always 29 bytes.

| Field         | Format   |
|:--------------|:---------|
| clockTime     | `float`  | 
| latitude      | `float`  | 
| ambient       | `float`  | 
| globalShadow  | `u8`     | 
| sunColor      | `Color3` |
| sunIntensity  | `float`  |


### PointLight

Always 17 bytes

| Field      | Format     | 
|:-----------|:-----------|
| lightColor | `Color3`   | 
| intensity  | `float`    |
| range      | `float`    | 
| castShadows| `u8`       | 

### SpotLight

Always 25 bytes.

| Field       | Format     | 
|:------------|:-----------|
| lightColor  | `Color3`   | 
| intensity   | `float`    | 
| range       | `float`    | 
| innerAngle  | `float`    | 
| outerAngle  | `float`    | 
| castShadows | `u8`       | 



### Script / ScriptHandle

Idk man

| Type         | Payload Size |
|:-------------|:-------------|
| Script       | 9 bytes      | 
| ScriptHandle | 15 bytes     | 