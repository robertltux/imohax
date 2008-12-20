// $Id: AvLocationHelper.lsl 21 2008-12-18 22:25:57Z imohax $
//
// Copyright (c) 2008, Mo Hax
// All rights reserved.
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

// this just turns on speaking the output to region channel
// for integration with other tools listening on that channel
integer channel = 0;

// or locally so others can see besides just owner
integer whisper = FALSE;

//WARNING: degrees can sometimes introduce visible conversion errors
// but are obviously easier to enter 'by hand' for this, persistent
// rotations should probably always be stored as raw rotations (quats)
integer rot_in_degrees = TRUE;

// experiment with changing this to odd values to prove not important
// avatar will not move from sit target unless adj_av* is set below
// NOTE: sit target is never the actual avatar position due to SL bugs
vector sit_target_vec = <0.0,0.0,0.01>;
vector sit_target_deg = <0.0,0.0,-25.0>;
rotation sit_target_rot = ZERO_ROTATION;

// use this one to simulate an animation correction adjustment
// adjusts local av pos and rot (from initial effective sit target)
vector adj_av_pos = <0.0,0.0,0.0>;
vector adj_av_deg = <0.0,0.0,180.0>;
rotation adj_av_rot = ZERO_ROTATION;

// regional position and rotation of avatar
vector pos;
rotation rot;

key avatar = NULL_KEY;

say(string message)
{
    if (whisper) llWhisper(0,message);
    else llOwnerSay(message);
    if (channel != 0) llRegionSay(channel,message);
}

default
{
    state_entry()
    {
        if (rot_in_degrees)
        {
            sit_target_rot = llEuler2Rot(sit_target_deg*DEG_TO_RAD);
            adj_av_rot = llEuler2Rot(adj_av_deg*DEG_TO_RAD);
        }
        llSitTarget(sit_target_vec, sit_target_rot);
        say("Ready");
    }

    // put this in touch so we can keep touching to add more adjustment
    touch_start(integer num)
    {
        if (avatar == NULL_KEY)
        {
            say("Please sit first. No avatar found.");
            return;
        }

        // sitting avatar is always the last link.
        integer av_link = llGetNumberOfPrims();

        // fetches the absolute region position and rotation of avatar
        // (without errors that would be introduced deriving from sit target)
        list details = llGetObjectDetails(avatar,[OBJECT_POS,OBJECT_ROT]);
        pos = llList2Vector(details,0);
        rot = llList2Rot(details,1);

        // since llGetObjectDetails() returns regional/global values
        // have to get the difference between av and root position and then
        // make sure result is in terms of the root rotation
        vector local_pos = (pos - llGetRootPosition())/llGetRootRotation();
        rotation local_rot = (rot / llGetRootRotation())/llGetRootRotation();

        // now we add adjustment in terms of avatar's local pos and rot
        vector adj_pos = local_pos + (adj_av_pos * local_rot);
        rotation adj_rot = local_rot * adj_av_rot;

        // for quick ref, some of the following is redundant to above
        say(
            "\nSit Target Postion:  "
                + (string) sit_target_vec + "\n" +
            "Sit Target Rotation:  "
                + (string) sit_target_rot + "\n" +
            "Sit Target Rotation (DEG):  "
                + (string) sit_target_deg + "\n\n" +

            "Av Region Position:  "
                + (string) pos + "\n" +
            "Av Region Rotation:  "
                + (string) rot + "\n" +
            "Av Region Rotation (DEG):  "
                + (string) (llRot2Euler(rot)*RAD_TO_DEG) + "\n\n" +

            // notice that these are NOT same as expected sit target due to SL bug
            "Av Local Position:  "
                + (string) ((pos - llGetRootPosition())/llGetRootRotation()) + "\n" +
            "Av Local Rotation:  "
                + (string) ((rot / llGetRootRotation())/llGetRootRotation()) + "\n" +
            "Av Local Rotation (DEG):  "
                + (string) (llRot2Euler(rot / llGetRootRotation())*RAD_TO_DEG) + "\n\n" +

            "Av Adjustment to Local Position:  "
                + (string) adj_av_pos + "\n" +
            "Av Adjustment to Local Rotation:  "
                + (string) adj_av_rot + "\n" +
            "Av Adjustment to Local Rotation: (DEG)  "
                + (string) (llRot2Euler(adj_av_rot)*RAD_TO_DEG) + "\n\n" +

            "Av Adjusted Local Position:  "
                + (string) (local_pos + (adj_av_pos * local_rot)) + "\n" +
            "Av Adjusted Local Rotation:  "
                + (string) (local_rot * adj_av_rot) + "\n" +
            "Av Adjusted Local Rotation (DEG):  "
                + (string) (llRot2Euler(local_rot * adj_av_rot)*RAD_TO_DEG));


        llSetLinkPrimitiveParams(av_link,[PRIM_POSITION,adj_pos,PRIM_ROTATION,adj_rot]);

        // this one demonstrates/proves the conversion from global to local above
        // note no change in avatar position or rotation at all
        //llSetLinkPrimitiveParams(av_link,[PRIM_POSITION,local_pos,PRIM_ROTATION,local_rot]);
    }

    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            llSleep(0.1);
            key new_av = llAvatarOnSitTarget();
            if (new_av != NULL_KEY)
                avatar = new_av;

            else
                avatar = NULL_KEY;
        }
    }
}