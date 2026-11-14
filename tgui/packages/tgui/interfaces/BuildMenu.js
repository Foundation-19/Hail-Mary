import { classes } from 'common/react';
import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, Input, NoticeBox, Section, Tabs } from '../components';
import { Window } from '../layouts';

// A search over the whole catalog can match a lot, so only some rows are drawn
const SEARCH_LIMIT = 120;

const maxMultiplier = (recipe, amount) => {
  let max = Math.floor(amount / recipe.req);
  if (recipe.max_res > 1) {
    max = Math.min(max, Math.floor(recipe.max_res / recipe.res));
  }
  return max;
};

export const BuildMenu = (props, context) => {
  const { data } = useBackend(context);
  const {
    categories = [],
    sources = [],
    recipes = [],
    amounts = {},
    crafts = {},
    focus,
  } = data;
  const [search, setSearch] = useLocalState(context, 'search', '');
  const [buildableOnly, setBuildableOnly] = useLocalState(
    context, 'buildableOnly', false);
  const [tab, setTab] = useLocalState(context, 'tab', null);

  const sourceOf = {};
  for (const source of sources) {
    sourceOf[source.key] = source;
  }

  // What each recipe needs and whether the player has it
  const stateOf = (recipe) => {
    if (recipe.kind === 'craft') {
      const state = crafts[recipe.ref] || {};
      return { can: !!state.ok, missing: state.missing, rank: 2 };
    }
    const have = amounts[recipe.source] || 0;
    const source = sourceOf[recipe.source] || {};
    const short = recipe.req - have;
    return {
      can: short <= 0,
      missing: short > 0 ? `${short} more ${source.name}` : '',
      rank: recipe.source === focus ? 0 : (have > 0 ? 1 : 3),
    };
  };

  const query = search.toLowerCase();
  const visible = [];
  recipes.forEach((recipe, order) => {
    const state = stateOf(recipe);
    if (buildableOnly && !state.can) {
      return;
    }
    if (query && !recipe.name.toLowerCase().includes(query)) {
      return;
    }
    visible.push({ recipe, state, order });
  });

  const usedCategories = categories.filter(
    category => visible.some(item => item.recipe.category === category));
  const firstBuildable = usedCategories.find(
    category => visible.some(item => (
      item.recipe.category === category && item.state.can)));
  const activeTab = query
    ? null
    : (usedCategories.includes(tab)
      ? tab
      : (firstBuildable || usedCategories[0]));

  const shown = visible
    .filter(item => !activeTab || item.recipe.category === activeTab)
    .sort((a, b) => (a.state.rank - b.state.rank) || (a.order - b.order));
  const limited = query ? shown.slice(0, SEARCH_LIMIT) : shown;

  // Keep the recipes of one material together under its heading
  const groups = [];
  for (const item of limited) {
    const { recipe } = item;
    const material = sourceOf[recipe.source]?.name;
    const title = recipe.kind === 'craft'
      ? recipe.group
      : (recipe.group ? `${material} - ${recipe.group}` : material);
    let group = groups.find(g => g.title === title);
    if (!group) {
      group = { title, items: [] };
      groups.push(group);
    }
    group.items.push(item);
  }

  const held = sources.filter(source => amounts[source.key] > 0);

  return (
    <Window
      theme="fallout"
      title="Builder"
      width={660}
      height={680}
      resizable>
      <Window.Content scrollable>
        <Section
          title="Materials"
          buttons={(
            <Button.Checkbox
              content="Buildable only"
              checked={buildableOnly}
              onClick={() => setBuildableOnly(!buildableOnly)} />
          )}>
          {held.length === 0 ? (
            <NoticeBox>
              Pick up some materials, or stand next to a pile, to build.
              Everything that can be built is listed, so you can see what to
              gather.
            </NoticeBox>
          ) : held.map(source => (
            <Box key={source.key} inline mr={2}>
              {source.name}: {amounts[source.key]}
            </Box>
          ))}
        </Section>
        <Input
          fluid
          placeholder="Search all recipes..."
          value={search}
          onInput={(e, value) => setSearch(value)} />
        <Flex mt={1}>
          <Flex.Item>
            <Tabs vertical>
              {usedCategories.map(category => (
                <Tabs.Tab
                  key={category}
                  selected={category === activeTab}
                  onClick={() => setTab(category)}>
                  {category}
                </Tabs.Tab>
              ))}
            </Tabs>
          </Flex.Item>
          <Flex.Item grow={1} basis={0}>
            {groups.length === 0 && (
              <NoticeBox>Nothing to build here.</NoticeBox>
            )}
            {groups.map(group => (
              <Section key={group.title} title={group.title} level={2}>
                {group.items.map(({ recipe, state }) => (
                  <RecipeRow
                    key={recipe.kind === 'craft'
                      ? recipe.ref
                      : `${recipe.source}-${recipe.idx}`}
                    recipe={recipe}
                    state={state}
                    amount={amounts[recipe.source] || 0}
                    unit={sourceOf[recipe.source]?.unit} />
                ))}
              </Section>
            ))}
            {query && shown.length > SEARCH_LIMIT && (
              <NoticeBox>
                Showing the first {SEARCH_LIMIT} of {shown.length}.
                Narrow the search to see the rest.
              </NoticeBox>
            )}
          </Flex.Item>
        </Flex>
      </Window.Content>
    </Window>
  );
};

const RecipeIcon = ({ recipe }) => (
  <Box
    inline
    mr={1}
    className={classes([recipe.icon])}
    style={{ 'vertical-align': 'middle' }} />
);

const RecipeRow = (props, context) => {
  const { act, data } = useBackend(context);
  const { recipe, state, amount, unit } = props;
  const { can, missing } = state;
  const disabled = !can || data.busy;
  const time = recipe.time ? `${recipe.time / 10}s` : '';

  if (recipe.kind === 'craft') {
    const needs = [
      recipe.req_text,
      recipe.tool_text && `using ${recipe.tool_text}`,
    ].filter(text => text).join(', ');
    return (
      <Flex align="center" className="candystripe" py={0.25}>
        <Flex.Item>
          <RecipeIcon recipe={recipe} />
        </Flex.Item>
        <Flex.Item grow={1} basis={0} color={can ? null : 'grey'}>
          <Box inline bold>{recipe.name}</Box>
          {' '}({needs}{time ? `, ${time}` : ''})
          {!can && !!missing && <Box color="bad">Missing: {missing}</Box>}
        </Flex.Item>
        <Flex.Item>
          <Button
            icon="hammer"
            content="Craft"
            tooltip={recipe.desc}
            tooltipPosition="left"
            disabled={disabled}
            onClick={() => act('craft', { ref: recipe.ref })} />
          {!!recipe.placeable && (
            <Button
              icon="crosshairs"
              content="Place"
              tooltip="Choose where to build it"
              tooltipPosition="left"
              disabled={disabled}
              onClick={() => act('place_craft', { ref: recipe.ref })} />
          )}
        </Flex.Item>
      </Flex>
    );
  }

  const max = maxMultiplier(recipe, amount);
  const cost = `${recipe.req} ${unit}${recipe.req > 1 ? 's' : ''}`;
  const base = {
    source: recipe.source,
    idx: recipe.idx,
    result: recipe.result,
  };
  const multipliers = [];
  if (recipe.max_res > 1 && max > 1) {
    for (const n of [5, 10, 25]) {
      if (max >= n) {
        multipliers.push(n);
      }
    }
    if (!multipliers.includes(max)) {
      multipliers.push(max);
    }
  }
  return (
    <Flex align="center" className="candystripe" py={0.25}>
      <Flex.Item>
        <RecipeIcon recipe={recipe} />
      </Flex.Item>
      <Flex.Item grow={1} basis={0} color={can ? null : 'grey'}>
        <Box inline bold>
          {recipe.res > 1 ? `${recipe.res}x ` : ''}{recipe.name}
        </Box>
        {' '}({cost}{time ? `, ${time}` : ''})
        {!can && !!missing && <Box color="bad">Need {missing}</Box>}
      </Flex.Item>
      <Flex.Item>
        {multipliers.map(n => (
          <Button
            key={n}
            content={`${n * recipe.res}x`}
            disabled={disabled}
            onClick={() => act('build', { ...base, multiplier: n })} />
        ))}
        <Button
          icon="hammer"
          content="Build"
          tooltip={recipe.desc}
          tooltipPosition="left"
          disabled={disabled}
          onClick={() => act('build', { ...base, multiplier: 1 })} />
        {!!recipe.placeable && (
          <Button
            icon="crosshairs"
            content="Place"
            tooltip="Choose where to build it, rotate with the mouse wheel"
            tooltipPosition="left"
            disabled={disabled}
            onClick={() => act('place', base)} />
        )}
      </Flex.Item>
    </Flex>
  );
};
