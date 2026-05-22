import { useBackend, useLocalState } from '../backend';
import { Box, Button, Input, Section, Flex, Dropdown } from '../components';
import { Window } from '../layouts';

type CreatePanelData = {
  mode: string;
  paths: string[];
  filter: string;
};

export const CreatePanel = (props, context) => {
  const { act, data } = useBackend<CreatePanelData>(context);
  const {
    mode = 'object',
    paths = [],
  } = data;

  const [search, setSearch] = useLocalState(context, 'search', '');
  const [selectedPath, setSelectedPath] = useLocalState(context, 'selectedPath', '');
  const [count, setCount] = useLocalState(context, 'count', '1');
  const [offset, setOffset] = useLocalState(context, 'offset', 'x,y,z');
  const [offsetType, setOffsetType] = useLocalState(context, 'offsetType', 'relative');
  const [dir, setDir] = useLocalState(context, 'dir', '');
  const [name, setName] = useLocalState(context, 'name', '');
  const [where, setWhere] = useLocalState(context, 'where', 'onfloor');

  const filteredPaths = search
    ? paths.filter(p => p.toLowerCase().includes(search.toLowerCase()))
    : paths;

  const whereOptions = [
    { value: 'onfloor', label: 'On floor below mob' },
    { value: 'frompod', label: 'Via supply pod' },
    { value: 'inhand', label: 'In mob\'s hand' },
    { value: 'inmarked', label: 'In marked object' },
  ];

  return (
    <Window width={500} height={600} title={`CREATE ${mode.toUpperCase()}`} theme="fallout">
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
        </Box>

        <Section title="> SEARCH">
          <Flex align="center" mb={1}>
            <Flex.Item basis="80px" style={{ color: '#4cff4c' }}>FILTER:</Flex.Item>
            <Flex.Item grow>
              <Input
                value={search}
                onInput={(_, v) => setSearch(v)}
                fluid
              />
            </Flex.Item>
          </Flex>
        </Section>

        <Section title="> OPTIONS">
          <Flex align="center" mb={1}>
            <Flex.Item basis="80px" style={{ color: '#4cff4c' }}>COUNT:</Flex.Item>
            <Flex.Item>
              <Input
                value={count}
                onInput={(_, v) => setCount(v)}
                width="60px"
              />
            </Flex.Item>
            <Flex.Item basis="40px" style={{ color: '#4cff4c', marginLeft: '10px' }}>DIR:</Flex.Item>
            <Flex.Item>
              <Input
                value={dir}
                onInput={(_, v) => setDir(v)}
                width="60px"
              />
            </Flex.Item>
          </Flex>

          <Flex align="center" mb={1}>
            <Flex.Item basis="80px" style={{ color: '#4cff4c' }}>OFFSET:</Flex.Item>
            <Flex.Item>
              <Input
                value={offset}
                onInput={(_, v) => setOffset(v)}
                width="120px"
              />
            </Flex.Item>
            <Button
              content="ABS"
              selected={offsetType === 'absolute'}
              onClick={() => setOffsetType('absolute')}
              style={{ marginLeft: '10px' }}
            />
            <Button
              content="REL"
              selected={offsetType === 'relative'}
              onClick={() => setOffsetType('relative')}
            />
          </Flex>

          <Flex align="center" mb={1}>
            <Flex.Item basis="80px" style={{ color: '#4cff4c' }}>NAME:</Flex.Item>
            <Flex.Item grow>
              <Input
                value={name}
                onInput={(_, v) => setName(v)}
                fluid
              />
            </Flex.Item>
          </Flex>

          <Flex align="center" mb={1}>
            <Flex.Item basis="80px" style={{ color: '#4cff4c' }}>WHERE:</Flex.Item>
            <Flex.Item grow>
              <Dropdown
                options={whereOptions.map(o => o.label)}
                selected={whereOptions.find(o => o.value === where)?.label || 'On floor below mob'}
                onSelected={v => {
                  const opt = whereOptions.find(o => o.label === v);
                  if (opt) setWhere(opt.value);
                }}
                width="100%"
              />
            </Flex.Item>
          </Flex>
        </Section>

        <Section
          title={`> ${mode.toUpperCase()} LIST (${filteredPaths.length})`}
        >
          <Box style={{ maxHeight: '250px', overflowY: 'auto' }}>
            {filteredPaths.slice(0, 500).map(path => (
              <Box
                key={path}
                style={{
                  padding: '4px 8px',
                  cursor: 'pointer',
                  backgroundColor: selectedPath === path ? 'rgba(76, 255, 76, 0.15)' : 'transparent',
                  border: selectedPath === path ? '1px solid #4cff4c' : '1px solid transparent',
                  marginBottom: '2px',
                }}
                onClick={() => setSelectedPath(path)}
              >
                {path}
              </Box>
            ))}
            {filteredPaths.length > 500 && (
              <Box style={{ color: '#ffaa00', padding: '8px', textAlign: 'center' }}>
                &gt; Results truncated. Use filter to narrow search.
              </Box>
            )}
          </Box>
        </Section>

        <Section>
          <Button
            fluid
            content="> SPAWN"
            color="good"
            disabled={!selectedPath}
            onClick={() => act('spawn', {
              path: selectedPath,
              count: count,
              offset: offset,
              offset_type: offsetType,
              dir: dir,
              name: name,
              where: where,
            })}
          />
        </Section>

        <Box className="CharacterSetup__footer">
          SLOT [CREATE {mode.toUpperCase()}] | READY
        </Box>
      </Window.Content>
    </Window>
  );
};
