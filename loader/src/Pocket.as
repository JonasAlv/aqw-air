package {

	import pocket.PocketRoot;

	public class Pocket extends PocketRoot {

		public static function get SINGLETON():Pocket {
			return PocketRoot.SINGLETON as Pocket;
		}

		public function Pocket() {
			super();
		}

	}
}
