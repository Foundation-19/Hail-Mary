import { useBackend, useLocalState } from '../backend';
import { Section, Flex, Button, Box, Input, Stack } from '../components';
import { Window } from '../layouts';

type VariableData = {
  name: string;
  value: any;
  type: string;
  ref?: string;
  is_editable?: boolean;
  sub_vars?: number;
};

type DatumInfo = {
  name: string;
  type: string;
  ref: string;
  is_marked?: boolean;
  is_edited?: boolean;
  is_deleted?: boolean;
};

type DropdownOption = {
  name: string;
  action: string;
};

type ViewVariablesData = {
  datum: DatumInfo;
  variables: VariableData[];
  dropdown_options: DropdownOption[];
};

const renderValue = (variable: VariableData, act: any) => {
  const { value, type, ref } = variable;

  if (type === 'null' || value === null || value === undefined) {
    return <span style={{ color: '#888' }}>null</span>;
  }

  if (type === 'text' || type === 'message') {
    const strVal = String(value);
    const displayVal = strVal.substring(0, 100);
    const suffix = strVal.length > 100 ? '...' : '';
    return (
      <span style={{ color: '#a8d8a8' }}>
        &quot;{displayVal}{suffix}&quot;
      </span>
    );
  }

  if (type === 'number' || type === 'bitfield') {
    return <span style={{ color: '#6bd8d8' }}>{String(value)}</span>;
  }

  if (type === 'list') {
    return (
      <span>
        <span style={{ color: '#d8a06b' }}>/list ({variable.sub_vars || 0})</span>
        {ref && (
          <Button
            content="[VIEW]"
            onClick={() => act('view_ref', { ref: ref })}
          />
        )}
      </span>
    );
  }

  if (type === 'datum' || type === 'atom' || type === 'mob' || type === 'client') {
    return (
      <span>
        <span style={{ color: '#d86b6b' }}>{String(value)}</span>
        {ref && (
          <Button
            content="[VIEW]"
            onClick={() => act('view_ref', { ref: ref })}
          />
        )}
      </span>
    );
  }

  if (type === 'type' || type === 'datum_type' || type === 'atom_type') {
    return <span style={{ color: '#b880d8' }}>{String(value)}</span>;
  }

  if (type === 'icon' || type === 'file') {
    return <span style={{ color: '#d8d86b' }}>{String(value)}</span>;
  }

  return <span>{String(value)}</span>;
};

export const ViewVariables = (props, context) => {
  const { act, data } = useBackend<ViewVariablesData>(context);
  const datum = data?.datum || { name: 'Unknown', type: 'Unknown', ref: '' };
  const variables = data?.variables || [];
  const dropdown_options = data?.dropdown_options || [];
  const [searchText, setSearchText] = useLocalState(context, 'searchText', '');

  const filteredVars = variables.filter(v =>
    !searchText
    || (v.name && v.name.toLowerCase().includes(searchText.toLowerCase()))
  );

  return (
    <Window width={600} height={700} title={`VV: ${datum.name}`} theme="fallout">
      <Window.Content scrollable>
        <Section title="Subject Data">
          <Flex justify="space-between" align="center">
            <Flex.Item>
              <Box style={{ fontSize: '18px', color: '#6bff6b' }}>
                {datum.name}
              </Box>
              <Box style={{ opacity: 0.7, fontSize: '12px' }}>
                TYPE: {datum.type}
              </Box>
              <Box style={{ opacity: 0.5, fontSize: '11px' }}>
                REF: {datum.ref}
              </Box>
            </Flex.Item>
            <Flex.Item>
              <Button
                content="> REFRESH"
                onClick={() => act('refresh')}
              />
            </Flex.Item>
          </Flex>
          {(datum.is_marked || datum.is_edited || datum.is_deleted) && (
            <Box mt={1}>
              {datum.is_marked && (
                <span style={{ color: '#ffaa00' }}>[MARKED] </span>
              )}
              {datum.is_edited && (
                <span style={{ color: '#ff6b6b' }}>[VARIABLES EDITED] </span>
              )}
              {datum.is_deleted && (
                <span style={{ color: '#ff0000' }}>[DELETED]</span>
              )}
            </Box>
          )}
        </Section>

        <Section title="Actions">
          <Flex gap={1} wrap>
            {dropdown_options.map((opt, idx) => (
              <Button
                key={idx}
                content={`> ${opt.name}`}
                onClick={() => act('dropdown_action', { action: opt.action })}
              />
            ))}
          </Flex>
        </Section>

        <Section title="Variable Query">
          <Input
            value={searchText}
            placeholder=">> ENTER SEARCH PARAMETERS..."
            fluid
            onChange={(e, value) => setSearchText(value)}
          />
          <Box style={{ fontSize: '11px', opacity: 0.6, marginTop: '5px' }}>
            E = Edit | C = Change (select type) | M = Mass edit
          </Box>
        </Section>

        <Section title={`Variables (${filteredVars.length})`}>
          <Stack vertical>
            {filteredVars.map((variable, idx) => (
              <Stack.Item key={idx}>
                <Box style={{ padding: '3px 5px', borderBottom: '1px solid #1a2a1a' }}>
                  <Flex align="flex-start">
                    {variable.is_editable && (
                      <Flex.Item shrink={0} style={{ marginRight: '5px' }}>
                        <Button
                          compact
                          content="E"
                          onClick={() => act('edit_var', { name: variable.name })}
                        />
                        <Button
                          compact
                          content="C"
                          onClick={() => act('change_var', { name: variable.name })}
                        />
                        <Button
                          compact
                          content="M"
                          onClick={() => act('mass_edit', { name: variable.name })}
                        />
                      </Flex.Item>
                    )}
                    <Flex.Item grow>
                      <span style={{ color: '#4cff4c', fontWeight: 'bold' }}>
                        {variable.name}
                      </span>
                      {' = '}
                      {renderValue(variable, act)}
                    </Flex.Item>
                  </Flex>
                </Box>
              </Stack.Item>
            ))}
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
