package med.display {
	import flash.display.Sprite;

	public class Content extends Sprite {

		// 2458, 1607
		static public function get WIDTH():Number { return (Main.WIDTH - Handle.TOTAL_WIDTH); }
		static public const HEIGHT:Number = Main.HEIGHT;
		
		protected var _full:Boolean;
		public function get full():Boolean { return _full; }		
		public function set full(value:Boolean):void { _full = value; }
		public var closed:Boolean;
		
		public var color:uint;

		protected var background:Background;
		
		protected var paused:Boolean;
		
		public function Content(color:uint) {
			
			this.color = color;
			
			background = new Background(WIDTH, HEIGHT);
			addChildAt(background, 0);
			background.showColor(color);
			
		}
		
		public function animate(dTime:Number):void {
			
		}
		
		public function pause():void {
			paused = true;
		}
		
		public function resume():void {
			paused = false;
		}
		
		public function reset():void {
			
		}
		

	}

}