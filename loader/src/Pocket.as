package {

	import flash.display.MovieClip;
	import pocket.PocketRoot;

	public class Pocket extends PocketRoot {

		public static function get SINGLETON():Pocket {
			return PocketRoot.SINGLETON as Pocket;
		}

		MovieClip.prototype.removeAllChildren = function ():void {
			var i:int = this.numChildren - 1;

			while (i >= 0) {
				this.removeChildAt(i);
				i--;
			}
		};

		public function Pocket() {
			super();
		}

	}
}
