// $Id$
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
integer gChannel = 0;

// or locally so others can see besides just owner
integer gWhisper = FALSE;

//WARNING: degrees can sometimes introduce visible conversion errors
// but are obviously easier to enter 'by hand' for this, persistent
// rotations should probably always be stored as raw rotations (quats)
integer gRotInDegrees = TRUE;

// experiment with changing this to odd values to prove not important
// avatar will not move from sit target unless adj_av* is set below
// NOTE: sit target is never the actual avatar position due to SL bugs
vector   gSitTargetPos = <0.0,0.0,0.01>;
vector   gSitTargetDeg = <0.0,0.0,-25.0>;
rotation gSitTargetRot = ZERO_ROTATION;

// use this one to simulate an animation correction adjustment
// adjusts local av pos and rot (from initial effective sit target)
vector   gAdjustPos = <0.0,0.0,0.0>;
vector   gAdjustDeg = <0.0,0.0,180.0>;
rotation gAdjustRot = ZERO_ROTATION;

key gAvatar = NULL_KEY;

say(string _message)
{
    if (gWhisper) llWhisper(0,_message);
    else llOwnerSay(_message);
    if (gChannel != 0) llRegionSay(gChannel,_message);
}

default
{
    state_entry()
    {
        if (gRotInDegrees)
        {
            gSitTargetRot = llEuler2Rot(gSitTargetDeg*DEG_TO_RAD);
            gAdjustRot = llEuler2Rot(gAdjustDeg*DEG_TO_RAD);
        }
        llSitTarget(gSitTargetPos, gSitTargetRot);
        say("Ready");
    }

    // put this in touch so we can keep touching to add more adjustment
    touch_start(integer _num)
    {
        if (gAvatar == NULL_KEY)
        {
            say("Please sit first. No avatar found.");
            return;
        }

        // fetches the absolute region position and rotation of avatar
        // (without errors that would be introduced deriving from sit target)
        list details = llGetObjectDetails(gAvatar,[OBJECT_POS,OBJECT_ROT]);
        vector posRegion   = llList2Vector(details,0);
        rotation rotRegion = llList2Rot(details,1);

        // since llGetObjectDetails() returns regional/global values
        // have to get the difference between av and root position and then
        // make sure result is in terms of the root rotation
        vector posLocal   = (posRegion-llGetRootPosition())/llGetRootRotation();
        rotation rotLocal = (rotRegion/llGetRootRotation())/llGetRootRotation();

        // now we add adjustment in terms of avatar's local pos and rot
        vector posAdjusted   = posLocal + (gAdjustPos * rotLocal);
        rotation rotAdjusted = rotLocal * gAdjustRot;

        // root of entire object link set, not just prim
        vector   posRoot = llGetRootPosition();
        rotation rotRoot = llGetRootRotation();

            // for quick ref, some of the following is redundant to above
            say(
                "\nSit Target Postion:  "
                    + (string) gSitTargetPos + "\n" +
            "Sit Target Rotation:  "
                + (string) gSitTargetRot + "\n" +
            "Sit Target Rotation (DEG):  "
                + (string) gSitTargetDeg + "\n\n" +

            "Av Region Position:  "
                + (string) posRegion + "\n" +
            "Av Region Rotation:  "
                + (string) rotRegion + "\n" +
            "Av Region Rotation (DEG):  "
                + (string) (llRot2Euler(rotRegion)*RAD_TO_DEG) + "\n\n" +

            // notice NOT same as expected sit target due to SL bug
            "Av Local Position:  "
                + (string) ((posRegion-posRoot)/rotRoot) + "\n" +
            "Av Local Rotation:  "
                + (string) ((rotRegion/rotRoot)/rotRoot) + "\n" +
            "Av Local Rotation (DEG):  "
                + (string) (llRot2Euler(rotRegion/rotRoot)*RAD_TO_DEG) + "\n\n" +

            "Av Adjustment to Local Position:  "
                + (string) gAdjustPos + "\n" +
            "Av Adjustment to Local Rotation:  "
                + (string) gAdjustRot + "\n" +
            "Av Adjustment to Local Rotation: (DEG)  "
                + (string) (llRot2Euler(gAdjustRot)*RAD_TO_DEG) + "\n\n" +

            "Av Adjusted Local Position:  "
                + (string) (posLocal + (gAdjustPos * rotLocal)) + "\n" +
            "Av Adjusted Local Rotation:  "
                + (string) (rotLocal * gAdjustRot) + "\n" +
            "Av Adjusted Local Rotation (DEG):  "
                + (string) (llRot2Euler(rotLocal * gAdjustRot)*RAD_TO_DEG));


        // sitting avatar is always the last link.
        integer avLink = llGetNumberOfPrims();
        llSetLinkPrimitiveParams(avLink,[
            PRIM_POSITION,posAdjusted,
            PRIM_ROTATION,rotAdjusted]
                );

        // this one demonstrates/proves the conversion from global to local above
        // note no change in avatar position or rotation at all
        //llSetLinkPrimitiveParams(av_link,[
        //    PRIM_POSITION,posLocal,
        //    PRIM_ROTATION,rotLocal]
        //);
    }

    changed(integer _change)
    {
        if (_change & CHANGED_LINK)
        {
            llSleep(0.1);
            key avatar = llAvatarOnSitTarget();
            if (avatar != NULL_KEY)
                gAvatar = avatar;

            else
                gAvatar = NULL_KEY;
        }
    }

}