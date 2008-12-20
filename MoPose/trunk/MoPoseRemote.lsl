// $Id: MoPoseRemote.lsl 18 2008-12-16 21:32:34Z imohax $

//TODO make it reposition based on the animations notecard, but only if needed
//TODO make it hide the poseball on sit
//TODO make animations notecard optional
//TODO autodetect changes to inventory and update script
//TODO make it say the animation name or friendly name when changed
//TODO make it read a special PAGE: line in the animations notecard
//TODO make it show different animation menus IM to sitter only with PGUP
//TODO make it jump 5 at a time if control is held down
//TODO make it read multiple animations notecards if found
//TODO internationalize, pull out any text into messages_EN notecard

key current_query;
integer data_line;

vector sit_target_vec = <0.0,0.0,0.01>;
rotation sit_target_rot = <0.0,0.0,0.0,1.0>;

list anim_names;
list anim_offset_vectors;
list anim_offset_rotations;
list anim_aliases;
list anim_durations;
integer total_anims;

string current_anim_name;
string current_anim_vec;
string current_anim_rot;
string current_anim_alias;
string current_anim_dur;

key avatar;
integer avatar_link;
string avatar_name;
vector avatar_pos;
vector avatar_local_pos;
rotation avatar_rot;
rotation avatar_local_rot;
vector avatar_velocity;

////////////////////////////////////////////////////////////////////////////

integer current_anim = 0;

playNext()
{
    integer next = current_anim+1;
    if (next <= total_anims) play(next);
    else play(1);
}

playPrev()
{
    integer prev = current_anim-1;
    if (prev >= 1) play(prev);
    else play(total_anims);
}

play(integer i)
{
    if (current_anim_name != "")
        llStopAnimation(current_anim_name);

    current_anim = i;
    current_anim_name = llList2String(anim_names,i);
    current_anim_vec = llList2String(anim_offset_vectors,i);
    current_anim_rot = llList2String(anim_offset_rotations,i);
    current_anim_alias = llList2String(anim_aliases,i);
    current_anim_dur = llList2String(anim_durations,i);

    rotation new_rot = avatar_local_rot * (rotation) current_anim_rot;
    vector new_pos = avatar_local_pos +
        (vector) current_anim_vec;

    llOwnerSay("sit_target_vec: " + (string) sit_target_vec);
    llOwnerSay("sit_target_rot: " + (string) sit_target_rot);
        llOwnerSay("avatar_local_pos: " + (string) avatar_local_pos);
    llOwnerSay("avatar_local_rot: " + (string) avatar_local_rot);

    llOwnerSay("new_p: " + (string) new_pos);
    llOwnerSay("new_r: " + (string) new_rot);
    llSetLinkPrimitiveParams(avatar_link,
        [PRIM_POSITION,new_pos,PRIM_ROTATION,new_rot]);
   llStartAnimation(current_anim_name);
}

////////////////////////////////////////////////////////////////////////////

default
{
    state_entry()
    {
        llOwnerSay("Starting up. Please wait for 'Ready' before using.");
        state reading_animations_notecard;
    }
}

////////////////////////////////////////////////////////////////////////////

state reading_animations_notecard
{
    state_entry()
    {
        if (llGetInventoryType("animations")!=INVENTORY_NOTECARD)
        {
            llOwnerSay("Failed to find required 'animations' notecard.");
            state error;
        }

        data_line = 0;
        current_query = NULL_KEY;

        anim_names = [""];
        anim_offset_vectors = [""];
        anim_offset_rotations = [""];
        anim_aliases = [""];
        anim_durations = [""];
        total_anims = 0;

        llOwnerSay("Reading animations notecard ...");

        current_query = llGetNotecardLine("animations",data_line);
    }

    dataserver(key query, string data)
    {
        if (data == EOF) state ready;
        if (query == current_query)
        {
            list p = llCSV2List(data);
            string name = llStringTrim(llList2String(p,0),STRING_TRIM);
            string offset_v = llStringTrim(llList2String(p,1),STRING_TRIM);
            string offset_r = llStringTrim(llList2String(p,2),STRING_TRIM);
            string alias = llStringTrim(llList2String(p,3),STRING_TRIM);
            string duration = llStringTrim(llList2String(p,4),STRING_TRIM);
            if (offset_v == "") offset_v = "<0.0,0.0,0.0>";
            if (offset_r == "") offset_r = "<0.0,0.0,0.0,1.0>";

            if (name == "")
            {
                llOwnerSay("WARNING: Skipping animation with no name: " + data);
            }
            else if (name == "SITTARGET")
            {
                sit_target_vec = (vector) offset_v;
                sit_target_rot = (rotation) offset_r;
            }
            else
            {
                anim_names += name;
                anim_offset_vectors += offset_v;
                anim_offset_rotations += offset_r;
                anim_aliases += alias;
                anim_durations += duration;
                ++total_anims;
            }

            ++data_line;
            current_query = llGetNotecardLine("animations",data_line);
        }
    }
}

////////////////////////////////////////////////////////////////////////////

state ready
{
    state_entry()
    {
        llOwnerSay("Ready");
        state waiting_for_avatar;
    }
}

////////////////////////////////////////////////////////////////////////////

state waiting_for_avatar
{
    state_entry()
    {
        avatar = NULL_KEY;
        avatar_link = 0;
        avatar_name = "";
        avatar_pos = ZERO_VECTOR;
        avatar_rot = ZERO_ROTATION;
        avatar_local_pos = ZERO_VECTOR;
        avatar_local_rot = ZERO_ROTATION;
        avatar_velocity = ZERO_VECTOR;

        llSitTarget(sit_target_vec, sit_target_rot);
    }

    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            llSleep(0.1); // let's av get to sit target
            key new_avatar = llAvatarOnSitTarget();
            if (new_avatar != NULL_KEY)
            {
                avatar = new_avatar;
                avatar_link = llGetNumberOfPrims();
                list details = llGetObjectDetails(avatar,[
                    OBJECT_NAME, OBJECT_POS, OBJECT_ROT, OBJECT_VELOCITY]);
                avatar_name = llList2String(details,0);
                avatar_pos = llList2Vector(details,1);
                avatar_rot = llList2Rot(details,2);
                avatar_velocity = llList2Vector(details,3);
                avatar_local_pos = (avatar_pos - llGetRootPosition())/llGetRootRotation();
                avatar_local_rot = avatar_rot / llGetRootRotation();
                state animating;
            }
        }
    }
}

////////////////////////////////////////////////////////////////////////////

state animating
{
    state_entry()
    {
        llRequestPermissions(avatar, PERMISSION_TRIGGER_ANIMATION
            | PERMISSION_TAKE_CONTROLS);
    }

    run_time_permissions(integer perms)
    {
        if (perms & (PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS))
        {
            llStopAnimation("sit");
            if (current_anim == 0) current_anim = 1;
            play(current_anim);
            llTakeControls(CONTROL_RIGHT|CONTROL_LEFT, TRUE, FALSE);
        }
    }

    control(key id, integer held, integer change)
    {
        if (held & change & CONTROL_RIGHT) playNext();
        if (held & change & CONTROL_LEFT) playPrev();
    }

    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            key new_avatar = llAvatarOnSitTarget();
            if (new_avatar == NULL_KEY) state stopping_animation;
        }
    }
}

////////////////////////////////////////////////////////////////////////////

state stopping_animation
{
    state_entry()
    {
        llReleaseControls();
        integer perms = llGetPermissions();
        if (perms & PERMISSION_TRIGGER_ANIMATION)
            llStopAnimation(current_anim_name);
        state waiting_for_avatar;
    }
}

////////////////////////////////////////////////////////////////////////////

state error
{
    state_entry()
    {
        llOwnerSay("ERROR STATE. Correct and reset script.");
    }
}