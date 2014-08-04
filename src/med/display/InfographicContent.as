package med.display {
	import med.infographic.Infographic;
	import med.infographic.InfographicData;

	public class InfographicContent extends Content {
		
		protected var infographicData:InfographicData;

		protected var infographic:Infographic;
		
		/*
		 * Default Infographic size is 1024 x 576
		 */
		
		public function InfographicContent(color:uint, infographicData:InfographicData) {
			super(color);
			this.infographicData = infographicData;
			
			infographic = new Infographic(infographicData, background);
			addChild(infographic);
			infographic.x = WIDTH / 2;
			infographic.y = HEIGHT / 2;
			var scale:Number = Math.min(WIDTH / 1024, HEIGHT / 576);
			infographic.scaleX = infographic.scaleY = scale;
			
		}
		
		override public function animate(dTime:Number):void {
			super.animate(dTime);
			
			infographic.animate(dTime);
		}

	}

}