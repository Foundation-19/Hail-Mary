import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Flex, Divider, Input } from '../components';
import { Window } from '../layouts';

type ResearchConsoleData = {
  locked: boolean;
  security_enabled: boolean;
  organization: string;
  research_control: boolean;
  points: Record<string, number>;
  income: Record<string, number>;
  has_lathe: boolean;
  has_imprinter: boolean;
  has_destroyer: boolean;
  has_tech_disk: boolean;
  has_design_disk: boolean;
  screen: number;
  nodes: NodeData[];
  researched_count: number;
  available_count: number;
  selected_node: NodeData | null;
  selected_design: DesignData | null;
  lathe_materials: MaterialData[];
  lathe_chemicals: ReagentData[];
  lathe_categories: string[];
  lathe_busy: boolean;
  lathe_designs: DesignBuildData[];
  imprinter_materials: MaterialData[];
  imprinter_chemicals: ReagentData[];
  imprinter_categories: string[];
  imprinter_busy: boolean;
  imprinter_designs: DesignBuildData[];
  destroyer_loaded: boolean;
  destroyer_item_name: string;
  destroyer_busy: boolean;
  tech_disk_nodes: NodeRefData[];
  design_disk_slots: DesignDiskSlot[];
  selected_category: string;
};

type NodeData = {
  id: string;
  name: string;
  description: string;
  category: string;
  tier: number;
  status: string;
  cost_display: string;
  can_afford: boolean;
  prereqs: NodeRefData[];
  unlocks: NodeRefData[];
  designs: DesignData[];
};

type NodeRefData = {
  id: string;
  name: string;
  researched: boolean;
};

type DesignRefData = {
  id: string;
  name: string;
};

type DesignData = {
  id: string;
  name: string;
  build_types: string[];
  materials: MaterialData[];
  reagents: ReagentData[];
  category: string[];
  unlocked_by: NodeRefData[];
};

type MaterialData = {
  name: string;
  amount: number;
  ref?: string;
  needed?: number;
  available?: number;
};

type ReagentData = {
  name: string;
  volume: number;
};

type DesignBuildData = {
  id: string;
  name: string;
  categories: string[];
  can_build: boolean;
  materials: MaterialData[];
};

type DesignDiskSlot = {
  slot: number;
  name: string | null;
  id: string | null;
};

const formatPoints = (points: number): string => {
  return points.toLocaleString();
};

export const ResearchConsole = (props, context) => {
  const { act, data } = useBackend<ResearchConsoleData>(context);
  const {
    locked = false,
    security_enabled = true,
    organization = "Unknown",
    research_control = true,
    points,
    income,
    has_lathe = false,
    has_imprinter = false,
    has_destroyer = false,
    has_tech_disk = false,
    has_design_disk = false,
    screen = 0,
    nodes = [],
    researched_count = 0,
    available_count = 0,
    selected_node,
    lathe_materials,
    lathe_chemicals,
    lathe_busy = false,
    lathe_designs = [],
    imprinter_materials,
    imprinter_chemicals,
    imprinter_busy = false,
    imprinter_designs = [],
    destroyer_loaded = false,
    destroyer_item_name = "",
    destroyer_busy = false,
    tech_disk_nodes = [],
    design_disk_slots = [],
    selected_category,
  } = data;

  const [searchText, setSearchText] = useLocalState(context, 'search', '');
  const [filterStatus, setFilterStatus] = useLocalState(context, 'filter', 'all');
  const [selectedDesignId, setSelectedDesignId] = useLocalState(context, 'selectedDesignId', null);

  const generalPoints = points?.['General Research'] || 0;
  const generalIncome = income?.['General Research'] || 0;

  const filteredNodes = nodes.filter(node => {
    const search = searchText.toLowerCase();
    if (searchText && !node.name.toLowerCase().includes(search)) {
      return false;
    }
    if (filterStatus !== 'all' && node.status !== filterStatus) {
      return false;
    }
    return true;
  });

  const researchedNodes = filteredNodes.filter(n => n.status === 'researched');
  const availableNodes = filteredNodes.filter(n => n.status === 'available');
  const lockedNodes = filteredNodes.filter(n => n.status === 'locked');

  return (
    <Window width={800} height={600} title="ROBCO TERMINAL" theme="fallout" resizable>
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
          <span style={{ float: 'right' }}>{(organization || "Unknown").toUpperCase()}</span>
        </Box>

        {locked ? (
          <Section title="> TERMINAL LOCKED">
            <Box style={{ textAlign: 'center', padding: '40px', color: '#ff3333', fontSize: '1.5em' }}>
              ACCESS DENIED
              <Box style={{ marginTop: '15px', color: '#2a7a52', fontSize: '0.8em' }}>
                Swipe ID card to unlock
              </Box>
              <Button
                content="[UNLOCK]"
                onClick={() => act('unlock')}
                style={{ marginTop: '20px' }}
              />
            </Box>
          </Section>
        ) : (
          <>
            <Section title="> SYSTEM STATUS">
              <Box style={{ fontSize: '1.2em', color: '#ffaa00' }}>
                RESEARCH POINTS: {formatPoints(generalPoints)}
              </Box>
              <Box style={{ color: '#4cff4c' }}>
                INCOME: +{generalIncome}/s
              </Box>
              <Box style={{ color: security_enabled ? '#4cff4c' : '#ff3333', marginTop: '8px' }}>
                SECURITY: {security_enabled ? 'ENABLED' : 'DISABLED'}
              </Box>
              <Box style={{ color: '#2a7a52', marginTop: '8px' }}>
                {researched_count} researched | {available_count} available
              </Box>
            </Section>

            <Section title="> NAVIGATION">
              <Flex wrap>
                <Flex.Item>
                  <Button
                    content="> TECHNOLOGY"
                    selected={screen === 1 || screen === 2 || screen === 3}
                    onClick={() => act('set_screen', { screen: 1 })}
                  />
                </Flex.Item>
                {has_lathe && (
                  <Flex.Item>
                    <Button
                      content="> PROTOLATHE"
                      selected={screen === 4}
                      onClick={() => act('set_screen', { screen: 4 })}
                    />
                  </Flex.Item>
                )}
                {has_imprinter && (
                  <Flex.Item>
                    <Button
                      content="> IMPRINTER"
                      selected={screen === 5}
                      onClick={() => act('set_screen', { screen: 5 })}
                    />
                  </Flex.Item>
                )}
                {has_destroyer && (
                  <Flex.Item>
                    <Button
                      content="> ANALYZER"
                      selected={screen === 6}
                      onClick={() => act('set_screen', { screen: 6 })}
                    />
                  </Flex.Item>
                )}
                {has_tech_disk && (
                  <Flex.Item>
                    <Button
                      content="> TECH DISK"
                      selected={screen === 7}
                      onClick={() => act('set_screen', { screen: 7 })}
                    />
                  </Flex.Item>
                )}
                {has_design_disk && (
                  <Flex.Item>
                    <Button
                      content="> DESIGN DISK"
                      selected={screen === 8}
                      onClick={() => act('set_screen', { screen: 8 })}
                    />
                  </Flex.Item>
                )}
                <Flex.Item>
                  <Button
                    content="> LOCK TERMINAL"
                    onClick={() => act('lock')}
                  />
                </Flex.Item>
              </Flex>
            </Section>

            {(screen === 1 || screen === 2 || screen === 3) && (
              <>
                <Section title="> SEARCH DATABASE">
                  <Flex>
                    <Flex.Item grow={2}>
                      <Input
                        fluid
                        placeholder="Enter search term..."
                        value={searchText}
                        onInput={(e, value) => setSearchText(value)}
                      />
                    </Flex.Item>
                    <Flex.Item grow={3} style={{ marginLeft: '10px' }}>
                      <Flex>
                        <Button
                          content="[ALL]"
                          selected={filterStatus === 'all'}
                          onClick={() => setFilterStatus('all')}
                        />
                        <Button
                          content="[RESEARCHED]"
                          selected={filterStatus === 'researched'}
                          onClick={() => setFilterStatus('researched')}
                        />
                        <Button
                          content="[AVAILABLE]"
                          selected={filterStatus === 'available'}
                          onClick={() => setFilterStatus('available')}
                        />
                        <Button
                          content="[LOCKED]"
                          selected={filterStatus === 'locked'}
                          onClick={() => setFilterStatus('locked')}
                        />
                      </Flex>
                    </Flex.Item>
                  </Flex>
                </Section>

                {selected_node ? (
                  <NodeDetailView
                    node={selected_node}
                    research_control={research_control}
                    onResearch={(id) => act('research_node', { node_id: id })}
                    onSelectNode={(id) => {
                      setSelectedDesignId(null);
                      act('select_node', { node_id: id });
                    }}
                    onBack={() => act('set_screen', { screen: 1 })}
                    selectedDesign={selected_node?.designs?.find(
                      d => d.id === selectedDesignId
                    )}
                    onSelectDesign={(id) => setSelectedDesignId(id)}
                  />
                ) : (
                  <>
                    {researchedNodes.length > 0 && (
                      <Section title={`> DONE (${researchedNodes.length})`}
                      >
                        {researchedNodes.map(node => (
                          <NodeRow
                            key={node.id}
                            node={node}
                            onClick={() => act('select_node', { node_id: node.id })}
                          />
                        ))}
                      </Section>
                    )}

                    {availableNodes.length > 0 && (
                      <Section title={`> AVAILABLE (${availableNodes.length})`}>
                        {availableNodes.map(node => (
                          <NodeRow
                            key={node.id}
                            node={node}
                            research_control={research_control}
                            onClick={() => act('select_node', { node_id: node.id })}
                            onResearch={(id) => act(
                              'research_node',
                              { node_id: id }
                            )}
                          />
                        ))}
                      </Section>
                    )}

                    {(filterStatus === 'all' || filterStatus === 'locked')
                      && lockedNodes.length > 0 && (
                      <Section title={`> LOCKED (${lockedNodes.length})`}>
                        {lockedNodes.slice(0, 20).map(node => (
                          <NodeRow
                            key={node.id}
                            node={node}
                            onClick={() => act('select_node', { node_id: node.id })}
                          />
                        ))}
                      </Section>
                    )}
                  </>
                )}
              </>
            )}

            {screen === 4 && (
              <ProductionMenu
                title="PROTOLATHE"
                materials={lathe_materials}
                chemicals={lathe_chemicals}
                designs={lathe_designs}
                busy={lathe_busy}
                selected_category={selected_category}
                onSelectCategory={(cat) => act('select_category', { category: cat })}
                onClearCategory={() => act('clear_category')}
                onBuild={(id, amt) => act('build', { design_id: id, amount: amt })}
                onEjectMaterial={(ref, amt) => act('eject_material', { ref, amount: amt })}
                onDisposeReagent={(name) => act('dispose_reagent', { target: 'lathe', reagent: name })}
                onDisposeAll={() => act('dispose_all_reagents', { target: 'lathe' })}
              />
            )}

            {screen === 5 && (
              <ProductionMenu
                title="CIRCUIT IMPRINTER"
                materials={imprinter_materials}
                chemicals={imprinter_chemicals}
                designs={imprinter_designs}
                busy={imprinter_busy}
                selected_category={selected_category}
                onSelectCategory={(cat) => act('select_category', { category: cat })}
                onClearCategory={() => act('clear_category')}
                onImprint={(id) => act('imprint', { design_id: id })}
                onEjectMaterial={(ref, amt) => act('eject_imprinter_material', { ref, amount: amt })}
                onDisposeReagent={(name) => act('dispose_reagent', { target: 'imprinter', reagent: name })}
                onDisposeAll={() => act('dispose_all_reagents', { target: 'imprinter' })}
                isImprinter
              />
            )}

            {screen === 6 && (
              <Section title="> DESTRUCTIVE ANALYZER">
                {destroyer_busy ? (
                  <Box style={{ textAlign: 'center', padding: '30px', color: '#ffaa00', fontSize: '1.3em' }}>
                    ANALYZING...
                  </Box>
                ) : destroyer_loaded ? (
                  <Box>
                    <Box style={{ color: '#4cff4c', fontSize: '1.2em', marginBottom: '10px' }}>
                      LOADED: {destroyer_item_name}
                    </Box>
                    <Button content="[EJECT ITEM]" onClick={() => act('eject_destroyer_item')} />
                    <Button content="[POINT DECONSTRUCTION]" onClick={() => act('deconstruct', { node_id: '__materials' })} />
                    <Button content="[DEEP SCAN]" onClick={() => act('deconstruct', { node_id: '__deepscan' })} />
                  </Box>
                ) : (
                  <Box style={{ textAlign: 'center', padding: '30px', color: '#2a7a52' }}>
                    No item loaded. Insert an item to analyze.
                  </Box>
                )}
              </Section>
            )}

            {screen === 7 && tech_disk_nodes && (
              <Section title="> TECHNOLOGY DISK">
                <Box style={{ marginBottom: '10px' }}>
                  <Button content="[UPLOAD TO DATABASE]" onClick={() => act('upload_tech_disk')} />
                  <Button content="[DOWNLOAD ALL]" onClick={() => act('download_tech_disk')} />
                  <Button content="[CLEAR DISK]" onClick={() => act('clear_tech_disk')} />
                  <Button content="[EJECT]" onClick={() => act('eject_tech_disk')} />
                </Box>
                <Box style={{ color: '#2a7a52', marginBottom: '10px' }}>
                  {tech_disk_nodes.length} nodes stored on disk
                </Box>
                {tech_disk_nodes.map(node => (
                  <Box
                    key={node.id}
                    style={{
                      border: '1px solid #1a5e38',
                      padding: '8px',
                      margin: '5px 0',
                      background: '#041a0e',
                      color: '#4cff4c',
                    }}
                  >
                    {node.name}
                  </Box>
                ))}
              </Section>
            )}

            {screen === 8 && design_disk_slots && (
              <Section title="> DESIGN DISK">
                <Box style={{ marginBottom: '10px' }}>
                  <Button content="[UPLOAD ALL]" onClick={() => act('upload_design_disk')} />
                  <Button content="[CLEAR ALL]" onClick={() => act('clear_design_disk_all')} />
                  <Button content="[EJECT]" onClick={() => act('eject_design_disk')} />
                </Box>
                {design_disk_slots.map(slot => (
                  <Box
                    key={slot.slot}
                    style={{
                      border: '1px solid #1a5e38',
                      padding: '10px',
                      margin: '5px 0',
                      background: '#041a0e',
                    }}
                  >
                    <Box style={{ color: '#888' }}>SLOT {slot.slot}:</Box>
                    {slot.name ? (
                      <>
                        <Box style={{ color: '#4cff4c' }}>{slot.name}</Box>
                        <Button
                          content="[UPLOAD]"
                          onClick={() => act('upload_design_disk', { slot: slot.slot })}
                        />
                        <Button
                          content="[CLEAR]"
                          onClick={() => act('clear_design_disk_slot', { slot: slot.slot })}
                        />
                      </>
                    ) : (
                      <Box style={{ color: '#666' }}>EMPTY</Box>
                    )}
                  </Box>
                ))}
              </Section>
            )}
          </>
        )}

        <Box className="CharacterSetup__footer">
          ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
        </Box>
      </Window.Content>
    </Window>
  );
};

const NodeRow = (props, context) => {
  const { node, research_control, onClick, onResearch } = props;

  const getStatusColor = () => {
    if (node.status === 'researched') return '#4cff4c';
    if (node.status === 'available') return '#ffcc00';
    return '#888';
  };

  return (
    <Box
      style={{
        border: '1px solid #1a5e38',
        padding: '12px',
        margin: '8px 0',
        background: '#041a0e',
      }}
    >
      <Flex justify="space-between" align="center">
        <Flex.Item onClick={onClick} style={{ cursor: 'pointer', flex: '1' }}>
          <Box style={{ color: getStatusColor(), fontWeight: 'bold', fontSize: '1.1em' }}>
            {node.status === 'researched' ? '[*]' : '[ ]'} {node.name}
          </Box>
          <Box style={{ color: '#2a7a52', fontSize: '0.9em', marginTop: '5px' }}>
            {node.description.substring(0, 60)}...
          </Box>
          {node.status === 'available' && (
            <Box style={{ color: node.can_afford ? '#ffaa00' : '#ff3333', marginTop: '5px' }}>
              Cost: {node.cost_display}
            </Box>
          )}
          {node.status === 'locked' && node.prereqs.length > 0 && (
            <Box style={{ color: '#666', fontSize: '0.85em', marginTop: '5px' }}>
              Requires: {node.prereqs.filter(p => !p.researched).map(p => p.name).join(', ')}
            </Box>
          )}
        </Flex.Item>
        {node.status === 'available' && research_control && node.can_afford && onResearch && (
          <Flex.Item>
            <Button
              content="[RESEARCH]"
              color="good"
              onClick={() => onResearch(node.id)}
            />
          </Flex.Item>
        )}
      </Flex>
    </Box>
  );
};

const NodeDetailView = (props, context) => {
  const {
    node, research_control, onResearch,
    onSelectNode, onBack, selectedDesign, onSelectDesign,
  } = props;
  const { act } = useBackend<ResearchConsoleData>(context);

  return (
    <>
      <Section>
        <Button content="[BACK TO LIST]" onClick={onBack} />
      </Section>

      <Flex spacing={1}>
        <Flex.Item grow basis="55%">
          <Section title={`> NODE: ${node.name.toUpperCase()}`}>
            <Box style={{ color: '#2a7a52', marginBottom: '15px', fontSize: '1.1em' }}>
              {node.description}
            </Box>

            {node.status === 'available' && (
              <Box
                style={{
                  border: '2px solid #ffaa00',
                  padding: '15px',
                  background: 'rgba(255,170,0,0.1)',
                  marginBottom: '15px',
                }}
              >
                <Box style={{ color: '#ffaa00', fontSize: '1.2em' }}>
                  COST: {node.cost_display}
                </Box>
                {research_control && node.can_afford && (
                  <Button
                    content="[RESEARCH NOW]"
                    color="good"
                    onClick={() => onResearch(node.id)}
                    style={{ marginTop: '10px' }}
                  />
                )}
              </Box>
            )}

            {node.status === 'researched' && (
              <Box
                style={{
                  border: '2px solid #4cff4c',
                  padding: '15px',
                  background: 'rgba(76,255,76,0.1)',
                  marginBottom: '15px',
                }}
              >
                <Box style={{ color: '#4cff4c', fontSize: '1.2em' }}>RESEARCHED</Box>
              </Box>
            )}

            <Divider />

            <Flex>
              {node.prereqs.length > 0 && (
                <Flex.Item grow basis="50%">
                  <Box style={{ color: '#4cff4c', fontWeight: 'bold', marginBottom: '10px' }}>
                    PREREQUISITES:
                  </Box>
                  {node.prereqs.map(prereq => (
                    <Box
                      key={prereq.id}
                      style={{
                        border: '1px solid #1a5e38',
                        padding: '8px',
                        margin: '5px 0',
                        background: '#041a0e',
                        color: prereq.researched ? '#4cff4c' : '#ff3333',
                        cursor: 'pointer',
                      }}
                      onClick={() => onSelectNode(prereq.id)}
                    >
                      [{prereq.researched ? 'x' : ' '}] {prereq.name}
                    </Box>
                  ))}
                </Flex.Item>
              )}

              <Flex.Item grow basis="50%">
                <Box style={{ color: '#4cff4c', fontWeight: 'bold', marginBottom: '10px' }}>
                  UNLOCKS:
                </Box>
                {node.unlocks.length > 0 ? (
                  node.unlocks.map(unlock => (
                    <Box
                      key={unlock.id}
                      style={{
                        border: '1px solid #1a5e38',
                        padding: '8px',
                        margin: '5px 0',
                        background: '#041a0e',
                        color: unlock.researched ? '#4cff4c' : '#ffcc00',
                        cursor: 'pointer',
                      }}
                      onClick={() => onSelectNode(unlock.id)}
                    >
                      {unlock.name}
                    </Box>
                  ))
                ) : (
                  <Box style={{ color: '#666' }}>None</Box>
                )}
              </Flex.Item>
            </Flex>

            <Divider />

            <Box style={{ color: '#4cff4c', fontWeight: 'bold', marginBottom: '10px' }}>
              DESIGNS ({node.designs.length}):
            </Box>
            {node.designs.length > 0 ? (
              node.designs.map(design => (
                <Box
                  key={design.id}
                  style={{
                    border: selectedDesign?.id === design.id ? '2px solid #ffaa00' : '1px solid #1a5e38',
                    padding: '8px',
                    margin: '5px 0',
                    background: selectedDesign?.id === design.id ? '#1a3a28' : '#041a0e',
                    color: selectedDesign?.id === design.id ? '#ffaa00' : '#4cff4c',
                    cursor: 'pointer',
                  }}
                  onClick={() => onSelectDesign(design.id)}
                >
                  {design.name}
                </Box>
              ))
            ) : (
              <Box style={{ color: '#666' }}>None</Box>
            )}
          </Section>
        </Flex.Item>

        <Flex.Item grow basis="45%">
          {selectedDesign ? (
            <Section title={`> DESIGN: ${selectedDesign.name.toUpperCase()}`}>
              <Box style={{ color: '#ffaa00', marginBottom: '10px' }}>
                BUILD TYPES:{' '}
                {selectedDesign.build_types.join(', ').toUpperCase() || 'NONE'}
              </Box>

              {selectedDesign.category?.length > 0 && (
                <Box style={{ color: '#2a7a52', marginBottom: '10px' }}>
                  CAT: {selectedDesign.category.join(', ')}
                </Box>
              )}

              <Divider />

              <Box style={{ color: '#4cff4c', fontWeight: 'bold', marginBottom: '10px' }}>
                MATERIALS:
              </Box>
              {selectedDesign.materials?.length > 0 ? (
                selectedDesign.materials.map((mat, idx) => (
                  <Box
                    key={idx}
                    style={{
                      color: '#4cff4c',
                      marginBottom: '5px',
                      paddingLeft: '10px',
                    }}
                  >
                    {mat.name}: {mat.amount}
                  </Box>
                ))
              ) : (
                <Box style={{ color: '#666', paddingLeft: '10px' }}>None</Box>
              )}

              {selectedDesign.reagents?.length > 0 && (
                <>
                  <Box style={{
                    color: '#4cff4c',
                    fontWeight: 'bold',
                    marginTop: '15px',
                    marginBottom: '10px',
                  }}>
                    REAGENTS:
                  </Box>
                  {selectedDesign.reagents.map((reag, idx) => (
                    <Box
                      key={idx}
                      style={{
                        color: '#4cff4c',
                        marginBottom: '5px',
                        paddingLeft: '10px',
                      }}
                    >
                      {reag.name}: {reag.volume}u
                    </Box>
                  ))}
                </>
              )}

              {selectedDesign.unlocked_by?.length > 0 && (
                <>
                  <Divider />
                  <Box style={{ color: '#4cff4c', fontWeight: 'bold', marginBottom: '10px' }}>
                    UNLOCKED BY:
                  </Box>
                  {selectedDesign.unlocked_by.map((unlocker, idx) => (
                    <Box
                      key={idx}
                      style={{
                        border: '1px solid #1a5e38',
                        padding: '8px',
                        margin: '5px 0',
                        background: '#041a0e',
                        color: unlocker.researched
                          ? '#4cff4c'
                          : '#ffcc00',
                        cursor: 'pointer',
                      }}
                      onClick={() => onSelectNode(unlocker.id)}
                    >
                      {unlocker.name}
                    </Box>
                  ))}
                </>
              )}
            </Section>
          ) : (
            <Section title="> DESIGN DETAILS">
              <Box style={{ textAlign: 'center', padding: '40px', color: '#2a7a52' }}>
                Click a design from the list to view details
              </Box>
            </Section>
          )}
        </Flex.Item>
      </Flex>
    </>
  );
};

const ProductionMenu = (props, context) => {
  const {
    title,
    materials,
    chemicals,
    designs,
    busy,
    selected_category,
    onSelectCategory,
    onClearCategory,
    onBuild,
    onImprint,
    onEjectMaterial,
    onDisposeReagent,
    onDisposeAll,
    isImprinter,
  } = props;

  const [showStorage, setShowStorage] = useLocalState(context, 'showStorage', false);
  const [searchText, setSearchText] = useLocalState(context, 'prodSearch', '');

  const filteredDesigns = designs.filter(d => {
    const search = searchText.toLowerCase();
    if (searchText && !d.name.toLowerCase().includes(search)) {
      return false;
    }
    return true;
  });

  const totalMaterials = materials?.reduce((sum, m) => sum + m.amount, 0) || 0;
  const totalChemicals = chemicals?.reduce((sum, r) => sum + r.volume, 0) || 0;

  return (
    <>
      <Section title={`> ${title}`}>
        <Box style={{ color: '#ffaa00', fontSize: '1.1em' }}>
          MATERIALS: {totalMaterials.toLocaleString()}
        </Box>
        <Box style={{ color: '#4cff4c' }}>
          CHEMICALS: {totalChemicals}u
        </Box>
        {busy && (
          <Box style={{ color: '#ffaa00', marginTop: '8px' }}>
            STATUS: {isImprinter ? 'IMPRINTING...' : 'BUILDING...'}
          </Box>
        )}
        <Button
          content={showStorage ? '[HIDE STORAGE]' : '[SHOW STORAGE]'}
          onClick={() => setShowStorage(!showStorage)}
          style={{ marginTop: '10px' }}
        />
      </Section>

      {showStorage && (
        <Section title="> STORAGE">
          <Flex>
            <Flex.Item grow basis="50%">
              {materials?.map(mat => (
                <Box key={mat.name} style={{ color: '#4cff4c', marginBottom: '5px' }}>
                  {mat.name}: {mat.amount.toLocaleString()}
                  {mat.ref && (
                    <span style={{ marginLeft: '10px' }}>
                      <Button
                        content="[EJECT]"
                        onClick={() => onEjectMaterial(mat.ref, 1)}
                      />
                    </span>
                  )}
                </Box>
              ))}
            </Flex.Item>
            <Flex.Item grow basis="50%">
              {chemicals && chemicals.length > 0 && (
                <>
                  <Box style={{ color: '#ffaa00', marginBottom: '10px' }}>CHEMICALS:</Box>
                  <Button
                    content="[DISPOSE ALL]"
                    color="bad"
                    onClick={() => onDisposeAll()}
                  />
                  {chemicals.map(chem => (
                    <Box key={chem.name} style={{ color: '#4cff4c', margin: '5px 0' }}>
                      {chem.name}: {chem.volume}u
                      <Button
                        content="[PURGE]"
                        color="bad"
                        onClick={() => onDisposeReagent(chem.name)}
                        style={{ marginLeft: '10px' }}
                      />
                    </Box>
                  ))}
                </>
              )}
            </Flex.Item>
          </Flex>
        </Section>
      )}

      <Section title="> SEARCH DESIGNS">
        <Input
          fluid
          placeholder="Search..."
          value={searchText}
          onInput={(e, value) => setSearchText(value)}
        />
      </Section>

      <Section title={`> DESIGNS (${filteredDesigns.length})`}>
        {filteredDesigns.length > 0 ? (
          filteredDesigns.map(design => (
            <Box
              key={design.id}
              style={{
                border: '1px solid #1a5e38',
                padding: '12px',
                margin: '8px 0',
                background: '#041a0e',
              }}
            >
              <Box style={{ color: design.can_build ? '#4cff4c' : '#888', fontWeight: 'bold' }}>
                {design.name}
              </Box>
              {design.can_build && !busy && (
                <Box style={{ marginTop: '8px' }}>
                  {isImprinter ? (
                    <Button
                      content="[IMPRINT]"
                      color="good"
                      onClick={() => onImprint(design.id)}
                    />
                  ) : (
                    <>
                      <Button
                        content="[x1]"
                        onClick={() => onBuild(design.id, 1)}
                      />
                      <Button
                        content="[x5]"
                        onClick={() => onBuild(design.id, 5)}
                      />
                      <Button
                        content="[x10]"
                        onClick={() => onBuild(design.id, 10)}
                      />
                    </>
                  )}
                </Box>
              )}
            </Box>
          ))
        ) : (
          <Box style={{ color: '#666', textAlign: 'center', padding: '20px' }}>
            No designs found
          </Box>
        )}
      </Section>
    </>
  );
};
