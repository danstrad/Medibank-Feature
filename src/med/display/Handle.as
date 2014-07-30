package med.display {
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class Handle extends Sprite {

		//133, 1607
		static public const WIDTH:Number = 133;
		static public const HEIGHT:Number = SwipeScreens.HEIGHT;
		

		public var content:Content;
		
		public var divider:Sprite;
		public var grab:Sprite;
		public var titleField:TextField;		
		private var bg:Sprite;
		
		protected var color:uint;

		public var left:Boolean;
		public var contentShowing:Boolean;
		public var prev:Handle;
		public var next:Handle;
		public var prevCount:int;
		public var nextCount:int;		
		public var homeX:Number;
		
		public var willBeVisible:Boolean;
		public var willBeLeft:Boolean;

		
		
		public function Handle(title:String, content:Content) {
			this.content = content;
			color = content.color;
			
			bg = new Sprite();
			addChildAt(bg, 1);
			bg.graphics.beginFill(color);
			bg.graphics.drawRect(0, 0, WIDTH, HEIGHT);
			
			
			prevCount = 0;
			nextCount = 0;
			
			titleField.text = title;
			
			hitArea = bg;
			
			buttonMode = true;
			mouseChildren = false;
		}

	}

}