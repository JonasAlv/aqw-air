package controller.walk;

import flash.display.MovieClip;
import flash.display.Sprite;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.Lib;

class MouseWalkSimulatorController extends WalkController {
    public static var IS_DASHING_ON:Bool = false;

    private static inline var SEND_EVERY_N_FRAMES:Int = 5;
    private static inline var MOVE_SPEED_MULTIPLIER:Float = 8.0;
    private static inline var WALK_MAX_THRESHOLD:Float = 0.65;
    private static inline var DASH_THRESHOLD:Float = 0.85;
    private static inline var DASH_COOLDOWN_MS:Int = 1000;

    private static var normalColor:ColorTransform = new ColorTransform();
    private static var dashColor:ColorTransform = new ColorTransform(0, 0, 0, 1, 0, 145, 0, 0);

    private var isDashingVisual:Bool = false;
    private var lastDashTime:Int = 0;

    public function new(pocket:Dynamic) {
        super(pocket);
    }

    override public function update():Void {
        if (this.pocket == null || this.pocket.game == null || this.pocket.game.world == null || this.pocket.game.world.myAvatar == null) {
            return;
        }

        var pMC:MovieClip = cast this.pocket.game.world.myAvatar.pMC;
        var joystick:Dynamic = (this.pocket.gameUI != null) ? this.pocket.gameUI.joystickMouseSimulator : null;
        if (joystick == null) return;

        var dirX:Float = joystick.dirX;
        var dirY:Float = joystick.dirY;

        var directionMagnitude:Float = Math.sqrt(dirX * dirX + dirY * dirY);

        if (pMC == null || directionMagnitude == 0) {
            return;
        }

        if (!this.pocket.game.world.isMoveOK(this.pocket.game.world.myAvatar.dataLeaf) || !(this.pocket.game.world.bitWalk == true)) {
            return;
        }

        var angle:Float = Math.atan2(dirY, dirX);
        var baseSpeed:Float = Std.parseFloat(Std.string(this.pocket.game.world.WALKSPEED));
        if (Math.isNaN(baseSpeed) || baseSpeed <= 0) baseSpeed = 8.0;

        var moveSpeed:Float = baseSpeed;

        if (IS_DASHING_ON && directionMagnitude >= DASH_THRESHOLD && !this.isDashingVisual) {
            if (joystick.knob != null) {
                joystick.knob.transform.colorTransform = dashColor;
            }
            this.isDashingVisual = true;
        } else if ((!IS_DASHING_ON || directionMagnitude < DASH_THRESHOLD) && this.isDashingVisual) {
            if (joystick.knob != null) {
                joystick.knob.transform.colorTransform = normalColor;
            }
            this.isDashingVisual = false;
        }

        if (directionMagnitude < WALK_MAX_THRESHOLD) {
            if (this.pocket.config != null && this.pocket.config.option_slow_walk == true) {
                moveSpeed = Math.max(baseSpeed * 0.3, baseSpeed * (directionMagnitude / WALK_MAX_THRESHOLD));
            } else {
                moveSpeed = baseSpeed;
            }
        } else if (directionMagnitude >= WALK_MAX_THRESHOLD && directionMagnitude < DASH_THRESHOLD) {
            moveSpeed = baseSpeed;
        } else if (IS_DASHING_ON && !(this.pocket.game.world.justRan2 == true)) {
            var currentTime:Int = Lib.getTimer();

            if (currentTime - this.lastDashTime >= DASH_COOLDOWN_MS) {
                var myAvatar:Dynamic = this.pocket.game.world.myAvatar;
                var playerName:String = myAvatar.pnm;
                var dashCost:Float = 100;
                try {
                    var uoTree:Dynamic = this.pocket.game.world.uoTree;
                    if (uoTree != null) {
                        var pData = Reflect.field(uoTree, playerName);
                        if (pData != null && pData.sta != null) {
                            var dshVal = Reflect.field(pData.sta, "$dsh");
                            if (dshVal != null) dashCost = Std.parseFloat(Std.string(dshVal));
                        }
                    }
                } catch (e:Dynamic) {}

                if (myAvatar.dataLeaf != null && myAvatar.dataLeaf.intSP >= dashCost) {
                    this.pocket.game.pDash = true;
                    this.lastDashTime = currentTime;
                }
            }
        }

        if (this.pocket.game.pDash == true && !(this.pocket.game.world.justRan2 == true)) {
            this.pocket.game.world.justRan2 = true;
            this.pocket.game.pDash = false;
        }

        if (this.pocket.game.world.justRan2 == true) {
            moveSpeed = baseSpeed * 3;
        }

        this.pocket.game.world.speed2 = moveSpeed;

        var localX:Float = pMC.x + Math.cos(angle) * MOVE_SPEED_MULTIPLIER * 10;
        var localY:Float = pMC.y + Math.sin(angle) * MOVE_SPEED_MULTIPLIER * 10;

        var stagePt:Point = (cast(this.pocket.game.world.CHARS, Sprite)).localToGlobal(new Point(localX, localY));

        if (stagePt.x < 0 || stagePt.x > 960 || stagePt.y < 0 || stagePt.y > 550) {
            return;
        }

        var mvPT:Point = pMC.simulateTo(localX, localY, moveSpeed);

        if (mvPT == null) {
            return;
        }

        pMC.walkTo(mvPT.x, mvPT.y, moveSpeed);

        this.frameTick++;

        if (this.frameTick >= SEND_EVERY_N_FRAMES) {
            this.frameTick = 0;

            this.pocket.game.world.moveRequest({
                mc: pMC,
                tx: mvPT.x,
                ty: mvPT.y,
                sp: moveSpeed
            });
        }
    }

    override public function stop():Void {
        this.frameTick = 0;

        if (this.pocket != null && this.pocket.game != null && this.pocket.game.world != null && this.pocket.game.world.myAvatar != null && this.pocket.game.world.myAvatar.pMC != null) {
            this.pocket.game.world.myAvatar.pMC.stopWalking();
        }

        if (this.isDashingVisual) {
            var joystick:Dynamic = (this.pocket.gameUI != null) ? this.pocket.gameUI.joystickMouseSimulator : null;
            if (joystick != null && joystick.knob != null) {
                joystick.knob.transform.colorTransform = normalColor;
            }
            this.isDashingVisual = false;
        }
    }
}
