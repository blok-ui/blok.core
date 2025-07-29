package counter;

import Breeze;
import blok.*;
import blok.html.Html;
import js.Browser;
import ui.*;

function counter() {
	blok.html.Client.mount(Browser.document.getElementById('counter-root'), Html.view(<Counter key="foo" count={1} />));
}

class Counter extends Component {
	@:signal final count:Int = 0;
	@:computed final countId:String = 'counter-${count()}';

	public function render():Child {
		return Html.view(<Container>
			<PanelHeader>
				<Title>"Counter"</Title>
			</PanelHeader>
			<PanelContent styles={Breeze.compose(
				Flex.display(),
				Flex.gap(5),
				Flex.direction('column'),
				Typography.fontWeight('bold'),
			)}>
				<div className={Breeze.compose(
					Flex.display(),
					Flex.gap(1.5),
					Flex.alignItems('center')
				)}>
					<span>'Current count'</span>
					// Blok requires strings to be wrapped in quotes, which is a bit
					// different than other DSLs. As a benefit of this, you can pass
					// identifiers directly as node children (like `count` here) without
					// wrapping them in brackets (like `{count}`).
					<div className={Breeze.compose(
						Spacing.pad('x', 3),
						Spacing.pad('y', 1),
						Border.radius(3),
						Background.color('black', 0),
						Typography.textColor('white', 0),
					)}>count</div>
				</div>
				<div className={Breeze.compose(
					Flex.display(),
					Flex.gap(3),
				)}>
					// You can declare attributes as child nodes:
					<Button>
						<action>{() -> if (count.peek() > 0) count.update(i -> i - 1)}</action>
						<label>
							// Svg should Just Work.
							<svg className={Breeze.compose(
								Sizing.height(8),
								Sizing.width(8),
								Layout.display('block'),
								Svg.fill('currentColor')
							)} viewBox="0 0 40 40">
								<path d="m24.875 11.199-11.732 8.8008 11.732 8.8008 1.2012-1.6016-9.5996-7.1992 9.5996-7.1992z"/>
							</svg>
						</label>
					</Button>
					<Button action={() -> count.update(i -> i + 1)}>
						<svg className={Breeze.compose(
							Sizing.height(8),
							Sizing.width(8),
							Layout.display('block'),
							Svg.fill('currentColor')
						)} viewBox="0 0 40 40">
							<path d="m15.125 11.199-1.2012 1.6016 9.5996 7.1992-9.5996 7.1992 1.2012 1.6016 11.732-8.8008z"/>
						</svg>
					</Button>
				</div>
			</PanelContent>
		</Container>);
	}
}
