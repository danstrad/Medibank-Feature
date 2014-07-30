package med.display {
	import med.infographic.Infographic;
	import med.infographic.InfographicData;

	public class InfographicContent extends Content {
		
		protected var infographicData:InfographicData;

		protected var infographic:Infographic;
		
		public function InfographicContent(color:uint, infographicData:InfographicData) {
			super(color);
			this.infographicData = infographicData;
			
			infographic = new Infographic(infographicData, background);
			addChild(infographic);
		}

	}

}