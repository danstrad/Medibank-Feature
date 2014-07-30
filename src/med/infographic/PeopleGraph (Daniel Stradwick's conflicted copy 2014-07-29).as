package med.infographic {
	import com.greensock.TweenMax;
	import com.gskinner.utils.Rndm;
	import flash.display.Sprite;
	
	
	public class PeopleGraph extends Sprite {

		// using a static array for this for performance / memory reasons
		protected static var people:Vector.<PeopleGraphPerson>;
				
		protected static const PEOPLE_SPACING:Number = 43;
		
		protected static const LEFTMOST_X_POSITION:Number = -415;
		protected static const RIGHTMOST_X_POSITION:Number = 415;
		
		
		public var isInNeutralState:Boolean;
		
		
		public function PeopleGraph() {
			var i:int;
			
			if (people == null) {
				// create vector for the first time
				people = new Vector.<PeopleGraphPerson>();
				
				for (i = 0; i < 100; i++) {
					var person:PeopleGraphPerson = new PeopleGraphPerson();
					people.push(person);
					addChild(person);
				}
			}
			
			// reset the graph to the "start" position
			var startX:int = -192;
			var startY:int = -189;
			
			for (i = 0; i < 100; i++) {
				var xIndex:int = i % 10;
				var yIndex:int = Math.floor(i / 10);

				person.rowIndex = yIndex;
				
				people[i].x = startX + (xIndex * PEOPLE_SPACING);
				people[i].y = startY + (yIndex * PEOPLE_SPACING);
				
				people[i].visible = false;
			}
			
			
			isInNeutralState = true;
			
			// hide text
			//textPanel.visible = false;
		}

		
		public function animateOn():void {
			// have the circles gradually appear in the neutral position
			
			// we want to stagger their appearance
			var rndm:Rndm = new Rndm(50);
			
			for each (var person:PeopleGraphPerson in people) {
				var animationDelayMsec:Number = Number(rndm.integer(0, 1000));
				person.animateOnPerson(animationDelayMsec);
			}
			
		}
		
		
		
		public function animateToGraphState(numTargetPeopleOnLeft:int, leftSideIsWhite:Boolean):void {
			// move the dots and change their color until we have the correct number of colored dots on each side
			var i:int;
			var person:PeopleGraphPerson;
			
			// figure out how many in each row are currently on each side (or neutral)
			var rowCountsLeft:Array = [];
			var rowCountsRight:Array = [];			
			
			
			for each (person in people) {
				
				if (person.state == PeopleGraphPerson.STATE_LEFT) {
					rowCountsLeft[person.rowIndex]++;
					
				} else if (person.state == PeopleGraphPerson.STATE_RIGHT) {
					rowCountsRight[person.rowIndex]++;
					
				}
				
			}
			
			
			
			// determine how many in each row SHOULD NEXT be on each side
			var numTargetPeopleOnRight:int = 100 - numTargetPeopleOnLeft;
			
			var targetRowCountsLeft:Array = [];
			var targetRowCountsRight:Array = [];
		
			
			for (i = 0; i < numPeopleOnRight; i++) {				
				// on the the right, they fill up from the top
				targetRowCountsRight[i % 10]++;
			}
			
			// we can infer the other side because there always ten people per row
			for (i = 0; i < 10; i++) {
				targetRowCountsLeft[i] = 10 - targetRowCountsLeft[i];                                                                                
			}
			
			
			// now nominate which people will move across
			for (var row:int = 0; row < 10; row++) {
				
				for (i = 0; i < 10; i++) { 
					people[(row * 10) + i]
			
				}
			}
			
			
			isInNeutralState = false;
			
		}
		
		
		
		
		
	}

}