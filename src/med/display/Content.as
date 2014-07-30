package med.display {
	import flash.display.Sprite;

	public class Content extends Sprite {

		// 2458, 1607
		static public function get WIDTH():Number { return Main.WIDTH - Handle.WIDTH * (Main.NUM_HANDLES - 1); }
		static public const HEIGHT:Number = Main.HEIGHT;
		
		protected var _full:Boolean;
		public function get full():Boolean { return _full; }		
		public function set full(value:Boolean):void { _full = value; }
		
		public var color:uint;

		protected var background:Background;
		
		public function Content(color:uint) {
			this.color = color;
			
			background = new Background(WIDTH, HEIGHT);
			addChildAt(background, 0);
			background.showColor(color);
			
		}
		
		public function animate(dTime:Number):void {
			
		}
		

	}

}