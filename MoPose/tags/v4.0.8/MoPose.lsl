// MoPose v4.0.8 (c) 2007 Copyright Mo Hax. All rights reserved.
// Released under BSD license for use in anything, commercial or otherwise
// AS LONG AS THIS COPYRIGHT AND NAME REMAIN UNCHANGED. Please support
// quality open scripts by letting Mo know of any changes you make
// or would like. Please note any and all changes in this header so Mo
// doesn't get blamed for your bugs and vice versa. ;)
// ALTHOUGH PERMISSION IS GIVEN TO USE THIS SCRIPT IN COMMERCIAL PRODUCTS,
// IF YOU USE THIS SCRIPT IN MODIFIABLE OBJECTS PLEASE KEEP SCRIPT PERMS
// COPY-MOD-TRANS TO ALLOW OTHERS TO ALSO USE (although you are not legally
// obligated to do so). Thank you.
//
// See About notecard for details on configuring this script.
//
// Simplified BSD License granted to all:
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
//     * Redistributions of source code must retain the above copyright notice,
//         this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//         notice, this list of conditions and the following disclaimer in the
//         documentation and/or other materials provided with the distribution.
//     * Neither the name of Mo Hax nor the names of its contributors may be
//         used to endorse or promote products derived from this software
//         without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
////////////////////////////////////////////////////////////////////////////////

integer pose_channel = 0;

integer show_positions = FALSE;

vector av_offset = <0.15,0,0>;
rotation av_rotation = <0,0,0,1>;

string sit_text = "Sit Here";
string hover_text = "";
string hover_text_color = "0/0/0/255";
integer sit_hides = TRUE;

integer hide_show = FALSE;
integer hide_show_channel = 1;

//////////////////// Toggle Two Animations /////////////////////////////////

integer toggle_anim = FALSE;
integer am_girl = TRUE;
integer toggle_color = TRUE;
string girl_color = "255/102/204";
string boy_color = "127/127/255";

integer toggle_hover = TRUE;
string boy_hover  = hover_text;
string girl_hover = hover_text;

integer toggle_hover_text_color = TRUE;
string girl_hover_text_color = "255/102/204";
string boy_hover_text_color = "127/127/255";

integer toggle_sit = TRUE;
string girl_sit = sit_text;
string boy_sit = sit_text;

string comment_char = "/";

////////////////////////////////////////////////////////////////////////////

string emotes_plugin = "MoEmotesPlugin v1.0.2 by Mo Hax";
vector color_vector;
float color_alpha;
vector hover_text_color_vector;
float hover_text_color_alpha;
string girl_anim;
string boy_anim;
vector girl_color_vector;
float girl_color_alpha;
vector girl_hover_text_color_vector;
float girl_hover_text_color_alpha;
vector boy_color_vector;
float boy_color_alpha;
vector boy_hover_text_color_vector;
float boy_hover_text_color_alpha;
key sitter = NULL_KEY;
key last_sitter = NULL_KEY;
integer sitter_link = 0;
string animation;
list animations;
integer anim_count;
integer anim_index = 0;
list emotes;
integer emotes_count;
float alpha_orig = 1.0;
integer has_config = FALSE;
integer listener;
integer pose_listener;
integer hidden = FALSE;
string instructions = "";
integer has_positions = FALSE;
list position_anims;
list position_vects;
list position_rots;
list sequence_anims;
list sequence_times;
integer sequence_index;
integer sequence_count;
float time_to_next_sequence;
integer _line;

integer MO_COMMAND          = 71992510; // str = <args>, key = <cmd>
integer MO_PROPERTY         = 71992513; // str = <value>, key = <propname>  (async)

hide()
{
    alpha_orig = llGetAlpha(ALL_SIDES);
    llSetAlpha(0.0, ALL_SIDES);
    llSetText("", hover_text_color_vector, hover_text_color_alpha);
    hidden = TRUE;
}

show()
{
    llSetText(hover_text, hover_text_color_vector, hover_text_color_alpha);
    llSetAlpha(alpha_orig, ALL_SIDES);
    hidden = FALSE;
}
    
rotation convertDegrees(vector eul)
{
    eul *= DEG_TO_RAD;
    rotation rot = llEuler2Rot(eul);
    return rot;
}

animate()
{
    if (has_positions)
    {
        string v;
        string r;
        integer i = llListFindList(position_anims,[animation]);
        if (i >= 0)
        {
            v = llList2String(position_vects,i);
            r = llList2String(position_rots,i);
        }
        else
        {
            v = (string) av_offset;
            r = (string) av_rotation;
        }
        if (show_positions) llOwnerSay("Position: " + animation + " " + v + " " + r);
        if (llGetLinkNumber() > 1)
        {
            llSetLinkPrimitiveParams(sitter_link,
            [PRIM_POSITION, (vector) v + llGetLocalPos(),
            PRIM_ROTATION, ((rotation) r / llGetRootRotation()) * llGetLocalRot()]);
        }
        else
        {
            llSetLinkPrimitiveParams(sitter_link,
                [PRIM_POSITION, (vector) v,
                PRIM_ROTATION, (rotation) r * (ZERO_ROTATION / llGetRot())]);
        }
    }
    llStartAnimation(animation);
}

handleSit()
{
    if (llAvatarOnSitTarget() == NULL_KEY) return;
    if (sit_hides) hide();
    sitter_link = llGetNumberOfPrims();
    llStopAnimation("sit");
    if (!sequence_count && !toggle_anim && anim_count > 1)
    {
        anim_index = llRound(llFrand(anim_count - 1));
        animation = llList2String(animations, anim_index);
    }
    else resetAnim();
    
    animate();
    
    if (sequence_count) llSetTimerEvent(time_to_next_sequence);
    if (emotes_count) llMessageLinked(LINK_SET, MO_COMMAND, "", "startEmotes");
    if (sitter != last_sitter && instructions != "") llInstantMessage(sitter, instructions);
    last_sitter = sitter;
}

handleStand()
{
    sitter_link = 0;
    llStopAnimation(animation);
    if (emotes_count) llMessageLinked(LINK_SET, MO_COMMAND, "", "stopEmotes");
    llReleaseControls();
    show();
}

cycleAnimation(integer direction)
{
    integer next_anim_index = anim_index + direction;
    if (next_anim_index > anim_count -1) next_anim_index = 0;
    else if (next_anim_index < 0) next_anim_index = anim_count -1;
    llStopAnimation(animation);
    anim_index = next_anim_index;
    animation = llList2String(animations, anim_index);
    animate();
}

loadAnimations()
{
    animations = [];
    anim_count = llGetInventoryNumber(INVENTORY_ANIMATION);
    integer i;
    for (i = 0; i < anim_count; ++i)
    {
        string anim = llGetInventoryName(INVENTORY_ANIMATION, i);
        if (llListFindList(emotes, [anim]) == -1) animations += anim;
    }
    resetAnim();
}

resetAnim()
{
    if (!toggle_anim)
    {
        if (!sequence_count)
        {
            anim_index = 0;
            animation = llList2String(animations, anim_index);
        }
        else
        {
            llSetTimerEvent(0);
            sequence_index = 0;
            animation = llList2String(sequence_anims, sequence_index);
        }
    }
}

integer boolFromString(string str)
{
     if (str == "yes" || str == "on" || str == "TRUE" || str == "true") return TRUE;
     return FALSE;
}

loadFromDescription()
{
    list attrs = llParseString2List(llGetObjectDesc(),["/"],[]);
    integer list_length = llGetListLength(attrs);
    string maybe_text;
    
    maybe_text = llList2String(attrs, 0);
    
    if (maybe_text != "(No Description)" && maybe_text != "")
        hover_text = maybe_text;
    
    if (list_length > 1) sit_text = llList2String(attrs, 1);
    
    if (list_length > 2)
        hover_text_color = llList2String(attrs,2) + "/" +
                           llList2String(attrs,3) + "/" +
                           llList2String(attrs,4) + "/" +
                           llList2String(attrs,5);
}


setGirlBoyColorVectors()
{
    list color_values = llParseString2List(girl_color,["/"],[]);
    girl_color_vector = <
        (float) (llList2Integer(color_values, 0)/255),
        (float) (llList2Integer(color_values, 1)/255),
        (float) (llList2Integer(color_values, 2)/255)
    >;
    girl_color_alpha = (float) (llList2Integer(color_values, 3)/255);
    
    color_values = llParseString2List(boy_color,["/"],[]);
    boy_color_vector = <
        (float) (llList2Integer(color_values, 0)/255),
        (float) (llList2Integer(color_values, 1)/255),
        (float) (llList2Integer(color_values, 2)/255)
    >;
    boy_color_alpha = (float) (llList2Integer(color_values, 3)/255);
    
    color_values = llParseString2List(girl_hover_text_color,["/"],[]);
    girl_hover_text_color_vector = <
        (float) (llList2Integer(color_values, 0)/255),
        (float) (llList2Integer(color_values, 1)/255),
        (float) (llList2Integer(color_values, 2)/255)
    >;
    girl_hover_text_color_alpha = (float) (llList2Integer(color_values, 3)/255);
    
    color_values = llParseString2List(boy_hover_text_color,["/"],[]);
    boy_hover_text_color_vector = <
        (float) (llList2Integer(color_values, 0)/255),
        (float) (llList2Integer(color_values, 1)/255),
        (float) (llList2Integer(color_values, 2)/255)
    >;
    boy_hover_text_color_alpha = (float) (llList2Integer(color_values, 3)/255);
}

setBoyOrGirl()
{
    if (am_girl)
    {
        animation = girl_anim;
        hover_text = girl_hover;
        hover_text_color = girl_hover_text_color;
        sit_text = girl_sit;
        color_vector = girl_color_vector;
        color_alpha = girl_color_alpha;
        hover_text_color_vector = girl_hover_text_color_vector;
        hover_text_color_alpha = girl_hover_text_color_alpha;
    }
    else
    {
        animation = boy_anim;
        hover_text = boy_hover;
        hover_text_color = boy_hover_text_color;
        sit_text = boy_sit;
        color_vector = boy_color_vector;
        color_alpha = boy_color_alpha;
        hover_text_color_vector = boy_hover_text_color_vector;
        hover_text_color_alpha = boy_hover_text_color_alpha;
    }    
}

setEmotesState(integer on)
{
    if (llGetInventoryType(emotes_plugin) == INVENTORY_SCRIPT)
        llSetScriptState(emotes_plugin, on);
    else if (!on) return;
    else llOwnerSay("Requires " + emotes_plugin + " for emotes support. Disabling emotes.");
}

handleProp(string data)
{
    integer eq_index = llSubStringIndex(data,"=");
    string prop = llStringTrim(llGetSubString(data,0,eq_index-1),STRING_TRIM);
    string value = llStringTrim(llGetSubString(data,eq_index+1,-1),STRING_TRIM);
    
    if (prop == "HoverText") { hover_text = value; jump out; }
    if (prop == "SitText") { sit_text = value; jump out;}
    if (prop == "HoverTextColor") { hover_text_color = value; jump out;}
    if (prop == "Offset") { av_offset = (vector) value; jump out;}
    if (prop == "Rotation") { av_rotation = (rotation) value; jump out;}
    if (prop == "HideShow") { hide_show = boolFromString(value); jump out;}
    if (prop == "SitHides") { sit_hides = boolFromString(value); jump out;}
    if (prop == "HideShowChannel") { hide_show_channel = (integer) value; jump out;}
    if (prop == "EmotesSeconds")
    {
        setEmotesState(TRUE);
        llMessageLinked(LINK_SET, MO_PROPERTY, value, "EmotesSeconds");
        jump out;
    }
    if (prop == "Emotes")
    {
        // just to keep out of master animation list
        emotes = llParseString2List(value, [" ", ","],[]);
        emotes_count = llGetListLength(emotes);
        setEmotesState(TRUE);
        llMessageLinked(LINK_SET, MO_PROPERTY, value, "Emotes");
        jump out;
    }
    if (prop == "ToggleAnim") { toggle_anim = boolFromString(value); jump out;}
    if (prop == "GirlAnim") { girl_anim = value; jump out;}
    if (prop == "BoyAnim") { boy_anim = value; jump out;}
    if (prop == "ToggleSitText") { toggle_sit = boolFromString(value); jump out;}
    if (prop == "GirlSitText") { girl_sit = value; jump out;}
    if (prop == "BoySitText") { boy_sit = value; jump out;}
    if (prop == "ToggleHoverText") { toggle_hover = boolFromString(value); jump out;}
    if (prop == "GirlHoverText") { girl_hover = value; jump out;}
    if (prop == "BoyHoverText") { boy_hover = value; jump out;}                   
    if (prop == "ToggleHoverTextColor")
    {
        toggle_hover_text_color = boolFromString(value);
        jump out;
    }
    if (prop == "GirlHoverTextColor") { girl_hover_text_color = value; jump out;}
    if (prop == "BoyHoverTextColor") { boy_hover_text_color = value; jump out;}
    if (prop == "ToggleColor") { toggle_color = boolFromString(value); jump out;}
    if (prop == "GirlColor") { girl_color = value; jump out;}
    if (prop == "BoyColor") { boy_color = value; jump out;}
    if (prop == "PoseChannel") { pose_channel = (integer) value; jump out;}
            
    @out;
}

default {
    state_entry() {
        alpha_orig = llGetAlpha(ALL_SIDES);
        setEmotesState(FALSE);
        state load_positions; 
    }
}

state load_positions
{
    state_entry()
    {
        if (llGetInventoryType("positions") != INVENTORY_NOTECARD)
        {
            has_positions = FALSE;
            state load_config;
        }
        
        llOwnerSay("Loading positions notecard ...");
        _line = 0;
        llGetNotecardLine("positions", _line);
    }
    
    dataserver(key queryid, string data)
    {
        if (data != EOF)
        {
            if (llGetSubString(data,0,0) == comment_char) return;
            
            list line = llCSV2List(data);
            string anim = llStringTrim(llList2String(line,0),STRING_TRIM);
            string vect = llStringTrim(llList2String(line,1),STRING_TRIM);
            string rota = llStringTrim(llList2String(line,2),STRING_TRIM);
            
            if (anim != "DEFAULT")
            {
            
                position_anims += anim;
            
                vector pos = llGetPos();
                vector anim_pos = pos + (vector) vect;
                float distance = llVecDist(pos,anim_pos);
            
                if (distance >= 5.0)
                    llOwnerSay("WARNING: '" + anim + 
                        "' position more than 5 meters away. SL likely ignoring.");
                if (vect != "") position_vects += vect;
                else position_vects += av_offset;
            
                if (rota != "") position_rots += convertDegrees((vector) rota);
                else position_rots += av_rotation;
               
            }
            
            else
            {
                av_offset = (vector) vect;
                av_rotation = convertDegrees((vector) rota);
            }
            
                 
            has_positions = TRUE;
            ++_line;
            llGetNotecardLine("positions", _line);
        }
        else
        {
            state load_config;
        }
    }
}

state load_config
{
    state_entry()
    {
        if (llGetInventoryType("config") != INVENTORY_NOTECARD)
        {
            has_config = FALSE;
            state load_description;
        }
        
        llOwnerSay("Loading config notecard ...");
        _line = 0;
        llGetNotecardLine("config", _line);
    }
    
    dataserver(key queryid, string data)
    {
        if (data != EOF)
        {
            integer past_last_div_index;
            integer div_index = llSubStringIndex(data,"||");
            integer eq_index = llSubStringIndex(data,"=");
            string initial_char = llGetSubString(data,0,0);
            if (initial_char == comment_char) ;
            else if (div_index > 0)
            {
                list props = llParseString2List(data,["||"],[]);
                integer count = llGetListLength(props);
                integer i;
                for (i=0; i< count; ++i) handleProp(llList2String(props,i));
            }
            else if (eq_index > 0) handleProp(data);
            ++_line;
            llGetNotecardLine("config", _line);
        }
        else
        {
            state load_animations;
        }
    }
}


state load_description
{
    state_entry()
    {
        loadFromDescription();
        state load_animations;
    }
}

state load_animations
{
    state_entry()
    {
        loadAnimations();
        state load_sequence;
    }
}

state load_sequence
{
    state_entry()
    {   
        sequence_index = 0;
        sequence_anims = [];
        sequence_times = [];
        
        if (llGetInventoryType("sequence") != INVENTORY_NOTECARD) state load_instructions;
        else if (toggle_anim)
        {
            llOwnerSay("Ignoring sequence notecard. Not allowed with ToggleAnim on");
            state load_instructions;
        }

        llOwnerSay("Loading sequence ...");
        _line = 0;
        llGetNotecardLine("sequence", _line);
    }
    
    dataserver(key queryid, string data)
    {
        if (data != EOF)
        {
            integer i = llSubStringIndex(data," ");
            sequence_times += (float) llGetSubString(data,0,i);
            sequence_anims += llStringTrim(llGetSubString(data,i+1,-1),STRING_TRIM);
            ++_line;
            llGetNotecardLine("sequence", _line);
        }
        else 
        {
            sequence_count = llGetListLength(sequence_anims);
            animation = llList2String(sequence_anims,0);
            time_to_next_sequence = llList2Float(sequence_times, 0);
            state load_instructions;
        }
    }
}

state load_instructions
{
    state_entry()
    {
        instructions = "";
        if (llGetInventoryType("instructions") != INVENTORY_NOTECARD) state active;
        llOwnerSay("Loading instructions notecard ...");
        instructions ="\n";
        _line = 0;
        llGetNotecardLine("instructions", _line);
    }
    
    dataserver(key queryid, string data)
    {
        if (data != EOF)
        {
            instructions += data + "\n";
            ++_line;
            llGetNotecardLine("instructions", _line);
        }
        else state active;
    }
}

state active
{
    state_entry()
    {
        llSitTarget( av_offset, av_rotation);
        color_alpha = alpha_orig;
        
        list color_values = llParseString2List(hover_text_color,["/"],[]);
        hover_text_color_vector = <
            (float) (llList2Integer(color_values, 0)/255),
            (float) (llList2Integer(color_values, 1)/255),
            (float) (llList2Integer(color_values, 2)/255)
        >;
        hover_text_color_alpha = (float) (llList2Integer(color_values, 3)/255);
        
        if (toggle_anim)
        {
            setGirlBoyColorVectors();
            setBoyOrGirl();
        }
        
        llSetText(hover_text, hover_text_color_vector, hover_text_color_alpha);
        llSetSitText(sit_text);

        if (hide_show == TRUE && !listener)
        {
            listener = llListen(hide_show_channel, "", NULL_KEY, "");
            llOwnerSay("Hide/Show channel listening on " + (string) hide_show_channel);
        }
        else if (hide_show == FALSE && listener)
        {
            llListenRemove(listener);
            listener = FALSE;
        }
        
        if (pose_channel != 0 && (!listener || pose_channel != hide_show_channel))
        {
            llOwnerSay("Pose channel listening on " + (string) pose_channel);
            pose_listener = llListen(pose_channel, "", NULL_KEY, "");
        }
        else if (pose_channel == 0 && pose_listener)
        {
            llListenRemove(pose_listener);
            pose_listener = FALSE;
        }
        
        llOwnerSay("Ready");
    }
    
    touch_start(integer num_detected) {
        if (!has_config) loadFromDescription();
     
        if (toggle_anim == TRUE) {
            if (am_girl) am_girl = FALSE;
            else am_girl = TRUE;
            setBoyOrGirl();
        }
        llSetText(hover_text, hover_text_color_vector, hover_text_color_alpha);
        llSetSitText(sit_text);
        if (color_vector != ZERO_VECTOR) llSetColor(color_vector, ALL_SIDES);
    }
    
    control(key id, integer held, integer change)
    {
        if (toggle_anim || sequence_count) return;
        integer released = ~held & change;
        if (released & CONTROL_UP) cycleAnimation(1);
        if (released & CONTROL_DOWN) cycleAnimation(-1);
    }
    
    changed(integer change) {
        
        if (change & CHANGED_LINK)
        {
            sitter = llAvatarOnSitTarget();
            if ( sitter != NULL_KEY)
            {
                llRequestPermissions(sitter,
                    PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS);
                if (emotes_count) llMessageLinked(LINK_SET, MO_PROPERTY, sitter, "Agent");
            }
            else
            {
                if (llGetPermissionsKey() != NULL_KEY) handleStand();
            }
        }
        
        else if (change & CHANGED_INVENTORY)
        {
            if (llGetInventoryType("no_reset") != INVENTORY_SCRIPT)
            {
                if (sitter != NULL_KEY) llUnSit(sitter);
                llSetAlpha(alpha_orig,ALL_SIDES);
                llResetScript();
            }
        }
    }
    
    listen(integer channel, string name, key id, string message)
    {
        if (channel == hide_show_channel)
        {
            if (message == "hide" && !hidden) hide();
            if (message == "show" && hidden) show();
        }
        if (channel == pose_channel && (id == sitter || llGetOwnerKey(id) == sitter))
        {
            if (message == "REQUEST_CONTROL")
            {
                llWhisper(pose_channel,"GRANT_CONTROL," + llList2CSV(animations));
                return;
            }
            if (animation != "") llStopAnimation(animation);
            llSetTimerEvent(0);
            animation = llStringTrim(message,STRING_TRIM);
            animate();
        }
    }
    
    timer()
    {
        if (llAvatarOnSitTarget() != NULL_KEY)
        {
             llStopAnimation(animation);
             if (sequence_index == sequence_count-1) sequence_index = 0;
             else ++sequence_index;
             animation = llList2String(sequence_anims, sequence_index);
             animate();
             llSetTimerEvent(llList2Float(sequence_times, sequence_index));
        }
        else llSetTimerEvent(0);
    }
    
    run_time_permissions(integer perm)
    {   
        if (perm & PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS)
        {
            llTakeControls(CONTROL_UP|CONTROL_DOWN, TRUE, FALSE);
            handleSit();
        }
    }
    
}