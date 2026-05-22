import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Flex } from '../components';
import { Window } from '../layouts';

type RealEstateTerminalData = {
  available_houses: AvailableHouse[];
  player_house: string | null;
};

type AvailableHouse = {
  house_id: string;
  name: string;
  description: string;
  tier: number;
  rent_cost: number;
  location_name: string;
  security_level: number;
  is_available: boolean;
};

const tierStars = (tier: number): string => {
  return '★'.repeat(tier) + '☆'.repeat(3 - tier);
};

const tierColor = (tier: number): string => {
  switch (tier) {
    case 1:
      return '#888';
    case 2:
      return '#ffd700';
    case 3:
      return '#4cff4c';
    default:
      return '#666';
  }
};

const securityName = (level: number): string => {
  switch (level) {
    case 1:
      return 'Basic';
    case 2:
      return 'Advanced';
    case 3:
      return 'Biometric';
    default:
      return 'Unknown';
  }
};

export const RealEstateTerminal = (props, context) => {
  const { act, data } = useBackend<RealEstateTerminalData>(context);
  const {
    available_houses = [],
    player_house,
  } = data;

  return (
    <Window width={600} height={550} title="REAL ESTATE TERMINAL" theme="fallout">
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          WASTELAND PROPERTIES
          <span style={{ float: 'right' }}>LISTINGS</span>
        </Box>

        {player_house && (
          <Section title="> YOUR PROPERTY">
            <Box
              style={{
                background: '#1a2a1a',
                border: '1px solid #4cff4c',
                padding: '10px',
                marginBottom: '10px',
              }}
            >
              <Box style={{ color: '#4cff4c' }}>
                You already own a property. Release it to claim another.
              </Box>
            </Box>
          </Section>
        )}

        <Section title="> AVAILABLE PROPERTIES">
          <Button
            content="[REFRESH LISTINGS]"
            onClick={() => act('refresh_listings')}
            style={{ marginBottom: '10px' }}
          />
          {available_houses.length > 0 ? (
            available_houses.map((house) => (
              <Box
                key={house.house_id}
                style={{
                  border: `1px solid ${house.is_available ? tierColor(house.tier) : '#333'}`,
                  padding: '12px',
                  margin: '8px 0',
                  background: house.is_available ? '#0a0a0a' : '#1a1a1a',
                  opacity: house.is_available ? 1 : 0.6,
                }}
              >
                <Flex justify="space-between" align="flex-start">
                  <Flex.Item grow={1}>
                    <Box
                      style={{
                        color: tierColor(house.tier),
                        fontWeight: 'bold',
                        marginBottom: '5px',
                      }}
                    >
                      {house.name} {tierStars(house.tier)}
                    </Box>
                    <Box style={{ color: '#888', fontSize: '0.9em', marginBottom: '8px' }}>
                      {house.description}
                    </Box>
                    <Box style={{ marginTop: '8px' }}>
                      <Flex wrap>
                        <Box style={{ color: '#ffd700', marginRight: '15px' }}>
                          Rent: {house.rent_cost} caps/week
                        </Box>
                        <Box style={{ color: '#4a90d9', marginRight: '15px' }}>
                          Location: {house.location_name}
                        </Box>
                        <Box style={{ color: '#b8d4f0' }}>
                          Security: {securityName(house.security_level)}
                        </Box>
                      </Flex>
                    </Box>
                  </Flex.Item>
                  <Flex.Item>
                    {house.is_available ? (
                      <Button
                        content="[CLAIM]"
                        color="good"
                        disabled={!!player_house}
                        onClick={() => act('claim_property', {
                          house_id: house.house_id,
                        })}
                      />
                    ) : (
                      <Box style={{ color: '#ff4444', fontWeight: 'bold' }}>TAKEN</Box>
                    )}
                  </Flex.Item>
                </Flex>
              </Box>
            ))
          ) : (
            <Box
              style={{
                textAlign: 'center',
                padding: '20px',
                color: '#666',
              }}
            >
              No properties available. Check back later.
            </Box>
          )}
        </Section>

        <Section title="> PROPERTY TIERS">
          <Box style={{ color: '#888', fontSize: '0.9em' }}>
            <Flex style={{ marginBottom: '8px' }}>
              <Box style={{ color: '#888', width: '80px' }}>★☆☆ Basic:</Box>
              <Box>Small shelter, basic lock, low rent</Box>
            </Flex>
            <Flex style={{ marginBottom: '8px' }}>
              <Box style={{ color: '#ffd700', width: '80px' }}>★★☆ Standard:</Box>
              <Box>Decent space, better security</Box>
            </Flex>
            <Flex>
              <Box style={{ color: '#4cff4c', width: '80px' }}>★★★ Premium:</Box>
              <Box>Large space, advanced security, amenities</Box>
            </Flex>
          </Box>
        </Section>

        <Section title="> RENTAL TERMS">
          <Box style={{ color: '#888', fontSize: '0.9em' }}>
            <Box>&gt; Pay weekly rent to maintain ownership.</Box>
            <Box>&gt; Late rent results in property release.</Box>
            <Box>&gt; One property per person.</Box>
            <Box>&gt; Upgrade security and add amenities.</Box>
            <Box>&gt; Authorize friends to access your home.</Box>
          </Box>
        </Section>

        <Box className="CharacterSetup__footer">
          WASTELAND PROPERTIES LLC - &quot;Home is where the bunker is.&quot;
        </Box>
      </Window.Content>
    </Window>
  );
};
