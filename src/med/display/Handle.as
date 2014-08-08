package med.display {
	import com.greensock.easing.Quad;
	import com.greensock.TweenMax;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.text.TextField;

	public class Handle extends _Handle {

		//133, 1607
		static public const TOTAL_WIDTH:Number = 399;
		static public var WIDTH:Number;
		static public const HEIGHT:Number = Main.HEIGHT;
		
		
		public var content:Content;
		
		private var bg:Sprite;
		
		public var homeColor:uint;

		public var prev:Handle;
		public var next:Handle;
		public var prevCount:int;
		public var nextCount:int;
		public var homeX:Number;
		
		public var left:Boolean;
		public var willBeLeft:Boolean;
		public var contentLeft:Boolean;
		
		protected var _draggable:Boolean;
		public function get draggable():Boolean { return _draggable; }
		public function set draggable(value:Boolean):void {
			_draggable = value;
			grab.visible = _draggable;
			buttonMode = _draggable;
		}
		
		
		public function Handle(title:String, content:Content) {
			this.content = content;
			homeColor = content.color;
			
			bg = new Sprite();
			bg.graphics.beginFill(0xFFFFFF);
			bg.graphics.drawRect(0, 0, WIDTH, HEIGHT);
			addChildAt(bg, 0);
			animateColor(homeColor, 0);
						
			prevCount = 0;
			nextCount = 0;
			
			titleField.text = title;
			titleField.x = (WIDTH - titleField.width) / 2;
			
			grab.x = WIDTH / 2;
			grab.gotoAndStop(1);
			
			hitArea = bg;
			
			buttonMode = true;
			mouseChildren = false;

			draggable = true;
		}
		
		public function showDragDirection():void {
			grab.gotoAndStop(2);
			if (willBeLeft) grab.scaleX = 1;
			else grab.scaleX = -1;
		}
		public function clearDragDirection():void {
			grab.gotoAndStop(1);
			grab.scaleX = 1;
		}
		
		
		public function animateColor(color:uint, time:Number):void {
			if (time > 0) {
				TweenMax.to(bg, time / 1000, { colorTransform:{ tint:color, tintAmount:1 }, ease:Quad.easeOut } ) 
			} else {
				var ct:ColorTransform = new ColorTransform(0, 0, 0, 1);
				ct.color = color;
				bg.transform.colorTransform = ct;
			}
		}
		
		

	}

}