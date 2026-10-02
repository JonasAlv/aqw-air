package controller.walk;

import flash.display.MovieClip;
import flash.display.Sprite;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.Lib;

class MouseWalkSimulatorController extends WalkController {
    public static var IS_DASHING_ON:Bool = false;

    private static inline var SEND_EVERY_N_FRAMES:Int = 2;
    private static inline var MOVE_SPEED_MULTIPLIER:Float = 8;
    private static inline var JOYSTICK_SPEED_MULTIPLIER:Float = 10;
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
        if (!this.pocket.game.world || !this.pocket.game.world.myAvatar) {
            return;
        }

        var world:Dynamic = this.pocket.game.world;
        var pMC:MovieClip = cast world.myAvatar.pMC;
        var joystick:Dynamic = this.pocket.gameUI.joystickMouseSimulator;
        var dirX:Float = joystick.dirX;
        var dirY:Float = joystick.dirY;
        var directionMagnitude:Float = Math.sqrt(dirX * dirX + dirY * dirY);

        if (pMC == null || directionMagnitude == 0) {
            return;
        }

        if (!world.isMoveOK(world.myAvatar.dataLeaf) || !untyped __global__["Boolean"](world.bitWalk)) {
            return;
        }

        var angle:Float = Math.atan2(dirY, dirX);
        var baseSpeed:Float = world.WALKSPEED;
        var moveSpeed:Float = baseSpeed;

        if (IS_DASHING_ON && directionMagnitude >= DASH_THRESHOLD && !isDashingVisual) {
            if (joystick.knob != null) {
                joystick.knob.transform.colorTransform = dashColor;
            }
            isDashingVisual = true;
        } else if ((!IS_DASHING_ON || directionMagnitude < DASH_THRESHOLD) && isDashingVisual) {
            if (joystick.knob != null) {
                joystick.knob.transform.colorTransform = normalColor;
            }
            isDashingVisual = false;
        }

        if (directionMagnitude < WALK_MAX_THRESHOLD) {
            if (this.pocket.config.option_slow_walk) {
                moveSpeed = Math.max(baseSpeed * 0.3, baseSpeed * (directionMagnitude / WALK_MAX_THRESHOLD));
            } else {
                moveSpeed = baseSpeed;
            }
        } else if (directionMagnitude < DASH_THRESHOLD) {
            moveSpeed = baseSpeed;
        } else if (IS_DASHING_ON && !world.justRan2) {
            var currentTime:Int = Lib.getTimer();
            if (currentTime - lastDashTime >= DASH_COOLDOWN_MS) {
                var myAvatar:Dynamic = world.myAvatar;
                var playerName:String = myAvatar.pnm;
                var dashCost:Float = 100;
                var playerData:Dynamic = (world.uoTree != null) ? Reflect.field(world.uoTree, playerName) : null;
                if (playerData != null && playerData.sta != null) {
                    var dashCostValue:Dynamic = Reflect.field(playerData.sta, "$dsh");
                    if (dashCostValue != null && dashCostValue != 0) {
                        dashCost = Std.parseFloat(Std.string(dashCostValue));
                    }
                }

                if (myAvatar.dataLeaf.intSP >= dashCost) {
                    this.pocket.game.pDash = true;
                    lastDashTime = currentTime;
                }
            }
        }

        if (this.pocket.game.pDash && !world.justRan2) {
            world.justRan2 = true;
            this.pocket.game.pDash = false;
        }

        if (world.justRan2) {
            moveSpeed = baseSpeed * 3;
        }

        moveSpeed *= JOYSTICK_SPEED_MULTIPLIER;
        world.speed2 = moveSpeed;

        var localX:Float = pMC.x + Math.cos(angle) * MOVE_SPEED_MULTIPLIER * 10;
        var localY:Float = pMC.y + Math.sin(angle) * MOVE_SPEED_MULTIPLIER * 10;
        var stagePoint:Point = cast(world.CHARS, Sprite).localToGlobal(new Point(localX, localY));
        if (stagePoint.x < 0 || stagePoint.x > 960 || stagePoint.y < 0 || stagePoint.y > 550) {
            return;
        }

        var movePoint:Point = pMC.simulateTo(localX, localY, moveSpeed);
        if (movePoint == null) {
            return;
        }

        pMC.walkTo(movePoint.x, movePoint.y, moveSpeed);

        frameTick++;
        if (frameTick >= SEND_EVERY_N_FRAMES) {
            frameTick = 0;
            world.moveRequest({
                mc: pMC,
                tx: movePoint.x,
                ty: movePoint.y,
                sp: moveSpeed
            });
        }
    }

    override public function stop():Void {
        frameTick = 0;

        if (this.pocket.game.world && this.pocket.game.world.myAvatar && this.pocket.game.world.myAvatar.pMC) {
            this.pocket.game.world.myAvatar.pMC.stopWalking();
        }

        if (isDashingVisual) {
            var joystick:Dynamic = this.pocket.gameUI.joystickMouseSimulator;
            if (joystick != null && joystick.knob != null) {
                joystick.knob.transform.colorTransform = normalColor;
            }
            isDashingVisual = false;
        }
    }
}
