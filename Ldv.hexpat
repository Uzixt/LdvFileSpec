// Written by @Uzixt
// File spec for .ldv

struct Header {
    char fileSignature[4]; // LSCN
    u32 fileVersion; // Currently 7, I'm almost certain its the file spec version but idk
    u16 recordCount;
};

enum ComponentType : u16 {
    Position = 0x0001,
    Rotation = 0x0002,
    Size = 0x0003,
    Name = 0x0004,
    
    Physics = 0x0014,
    Anchored = 0x0015, 
    Locked = 0x0016, 
    Color3 = 0x001E,
    Transparency = 0x001F,
    Material = 0x0020,
    SpawnPoints = 0x0032, 
    NetworkId = 0x003C,
    Lighting = 0x006E, 
    ChildOfPair = 0x005A,
    
    ScriptHandle = 0x0047, // dont bother trying to understand scripthandles/scripts
                            // its not implemented properly in the save file
    Script = 0x0048, 
    
    // SHAPES
    // These records don't store a value, just ids
    // Idk why each shape is it own record
    BoxShapeType = 0x000A,
    SphereShapeType = 0x000B,
    CylinderShapeType = 0x000C,
    ConeShapeType = 0x000D,
    WedgeShapeType = 0x000E,
    
    // Lighting Components
    PointLight = 0x0064,
    SpotLight = 0x0065
};

// Data structs
struct Vec3 {float x, y, z;}; 
struct Quat {float x, y, z, w;}; // Rotation is stored as quaternions
struct Color3 {float R, G, B;};

struct Physics {
    float Friction;
    float Restitution;
    float Density;
};

struct String {char text[64];};

struct EntityId {
    u32 entityId;
    u32 entityGeneration; // luduvo reuses entities
};


// "Instance" structs
// some stuff like Lighting, PointLight, and SpotLight store their data all in one struct

struct Lighting {
    float clockTime;
    float latitude;
    float ambient;
    u8 globalShadow; //boolean
    Color3 sunColor;
    float sunIntensity;
};

struct BaseLight {
    Color3 lightColor;
    float intensity;
    float range;
};

struct PointLight {
    BaseLight baseLight;
    u8 castShadows; //boolean
};

struct SpotLight {
    BaseLight baseLight;
    float innerAngle;
    float outerAngle;
    u8 castShadows;
};


// Misc stuff
struct Script {
    u8 noFuckingClue[9];
};

struct ScriptHandle {
    u8 noFuckingClue[15];
};

struct Entry<T> {
    EntityId entityId;
    T value;
};

struct EntryRaw<auto VS> {
    // fallback for undocumented components
    EntityId entityId;
    u8 value[VS];
};

struct Record {
    ComponentType type;
    u16 valueSize;
    u32 numberOfEntries;
    
    // theres a better way to handle this without all the if-else slop, 
    //  but ts is good enough for now
    
    if (valueSize == 0) {
        // for some reason the record for script and scripthandles
        // report a value size of 0, even though their entries have data associated
        // with them bruh
        
        if (type == ComponentType::Script) {
            Entry<Script> entries[numberOfEntries];
        } else if (type == ComponentType::ScriptHandle) {
            Entry<ScriptHandle> entries[numberOfEntries];
        } else {
            // the record is purely used for storing and tagging entities, like
            // shape components. 
            EntityId entries[numberOfEntries];
        }
    } else if (type == ComponentType::Position || 
        type == ComponentType::Size) {
        // components which store vec3 data
            Entry<Vec3> entries[numberOfEntries];
    } else if (type == ComponentType::Color3) {
        Entry<Color3> entries[numberOfEntries];
    } else if (type == ComponentType::Physics) {
        Entry<Physics> entries[numberOfEntries];
    } else if (type == ComponentType::Rotation) {
        Entry<Quat> entries[numberOfEntries];
    } else if (type == ComponentType::Name) {
        Entry<String> entries[numberOfEntries];
    } else if (type == ComponentType::Lighting) {
        Entry<Lighting> entries[numberOfEntries];
    }  else if (type == ComponentType::PointLight) {
        Entry<PointLight> entries[numberOfEntries];
    } else if (type == ComponentType::SpotLight) {
        Entry<SpotLight> entries[numberOfEntries];
    } else if (valueSize == 4) {
        Entry<float> entries[numberOfEntries];
    } else if (valueSize == 8) {
        Entry<u64> entries[numberOfEntries];
    } else {
        // fallback
        EntryRaw<valueSize> entries[numberOfEntries];
    }
};

struct LdvFile {
    Header header;
    Record records[header.recordCount];
};

LdvFile file @ 0x00;