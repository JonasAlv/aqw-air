package controller.walk;

import flash.display.MovieClip;
import flash.display.Sprite;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.Lib;

/**
 * Virtual Analog Mouse Walk Simulator Controller.
 * Simulates smooth 360-degree character walking and sprint/dash in AQW.
 */
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

        var world:Dynamic = this.pocket.game.world;
        var canMove:Bool = true;
        try {
            if (world.isMoveOK != null && world.myAvatar.dataLeaf != null) {
                canMove = world.isMoveOK(world.myAvatar.dataLeaf);
            }
        } catch (_:Dynamic) {}
        if (!canMove) return;

        if (world.bitWalk == false || world.bitWalk == 0) return;

        var angle:Float = Math.atan2(dirY, dirX);
        var baseSpeed:Float = Std.parseFloat(Std.string(world.WALKSPEED));
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
        } else if (IS_DASHING_ON && !(world.justRan2 == true)) {
            var currentTime:Int = Lib.getTimer();

            if (currentTime - this.lastDashTime >= DASH_COOLDOWN_MS) {
                var myAvatar:Dynamic = world.myAvatar;
                var playerName:String = myAvatar.pnm;
                var dashCost:Float = 100;
                try {
                    var uoTree:Dynamic = world.uoTree;
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

        if (this.pocket.game.pDash == true && !(world.justRan2 == true)) {
            world.justRan2 = true;
            this.pocket.game.pDash = false;
        }

        if (world.justRan2 == true) {
            moveSpeed = baseSpeed * 3;
        }

        world.speed2 = moveSpeed;

        var localX:Float = pMC.x + Math.cos(angle) * MOVE_SPEED_MULTIPLIER * 10;
        var localY:Float = pMC.y + Math.sin(angle) * MOVE_SPEED_MULTIPLIER * 10;

        if (world.CHARS != null) {
            var charsSp:Sprite = cast world.CHARS;
            var stagePt:Point = charsSp.localToGlobal(new Point(localX, localY));
            var stageW:Float = (this.pocket.game.stage != null && this.pocket.game.stage.stageWidth > 0) ? this.pocket.game.stage.stageWidth : 960;
            var stageH:Float = (this.pocket.game.stage != null && this.pocket.game.stage.stageHeight > 0) ? this.pocket.game.stage.stageHeight : 550;

            if (stagePt.x < -50 || stagePt.x > stageW + 50 || stagePt.y < -50 || stagePt.y > stageH + 50) {
                return;
            }
        }

        var mvPT:Point = pMC.simulateTo(localX, localY, moveSpeed);

        if (mvPT == null) {
            return;
        }

        pMC.walkTo(mvPT.x, mvPT.y, moveSpeed);

        this.frameTick++;

        if (this.frameTick >= SEND_EVERY_N_FRAMES) {
            this.frameTick = 0;

            world.moveRequest({
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
