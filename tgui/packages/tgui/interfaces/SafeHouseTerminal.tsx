import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Flex, Input, NumberInput } from '../components';
import { Window } from '../layouts';

type SafeHouseTerminalData = {
  house_id: string;
  name: string;
  description: string;
  tier: number;
  owner_ckey: string;
  owner_name: string;
  authorized_users: string[];
  rent_cost: number;
  rent_paid_until: number;
  rent_days_remaining: number;
  claimed_time: number;
  security_level: number;
  amenities: string[];
  location_name: string;
  locked: boolean;
  alarm_active: boolean;
  upgrade_costs: Record<string, number>;
  is_owner: boolean;
  is_authorized: boolean;
  can_claim: boolean;
  error?: string;
};

const tierStars = (tier: number): string => {
  return '★'.repeat(tier) + '☆'.repeat(3 - tier);
};

const tierName = (tier: number): string => {
  switch (tier) {
    case 1:
      return 'Basic';
    case 2:
      return 'Standard';
    case 3:
      return 'Premium';
    default:
      return 'Unknown';
  }
};

const securityName = (level: number): string => {
  switch (level) {
    case 1:
      return 'Basic Lock';
    case 2:
      return 'Advanced Lock';
    case 3:
      return 'Biometric Scanner';
    default:
      return 'Unknown';
  }
};

export const SafeHouseTerminal = (props, context) => {
  const { act, data } = useBackend<SafeHouseTerminalData>(context);
  const {
    name,
    description,
    tier,
    owner_ckey,
    owner_name,
    authorized_users = [],
    rent_cost,
    rent_days_remaining,
    security_level,
    amenities = [],
    location_name,
    locked,
    upgrade_costs,
    is_owner,
    is_authorized,
    can_claim,
    error,
  } = data;

  const [newUser, setNewUser] = useLocalState(context, 'newUser', '');
  const [rentWeeks, setRentWeeks] = useLocalState(context, 'rentWeeks', 1);

  if (error) {
    return (
      <Window width={500} height={400} title="SAFE HOUSE TERMINAL" theme="fallout">
        <Window.Content>
          <Section>
            <Box style={{ color: '#ff4444', textAlign: 'center' }}>{error}</Box>
          </Section>
        </Window.Content>
      </Window>
    );
  }

  return (
    <Window width={550} height={600} title="SAFE HOUSE TERMINAL" theme="fallout">
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          {name}
          <span style={{ float: 'right' }}>{tierName(tier)} {tierStars(tier)}</span>
        </Box>

        {!owner_ckey && (
          <Section title="> PROPERTY AVAILABLE">
            <Box style={{ color: '#b8d4f0', marginBottom: '10px' }}>
              {description}
            </Box>
            <Box style={{ color: '#888', marginBottom: '10px' }}>
              Location: {location_name}
            </Box>
            <Box style={{ color: '#ffd700', marginBottom: '15px' }}>
              Rent: {rent_cost} caps/week
            </Box>
            {can_claim ? (
              <Button
                content="[CLAIM PROPERTY]"
                color="good"
                onClick={() => act('claim_house')}
              />
            ) : (
              <Box style={{ color: '#ff4444' }}>
                You already own another property.
              </Box>
            )}
          </Section>
        )}

        {owner_ckey && (
          <>
            <Section title="> PROPERTY STATUS">
              <Box style={{ marginBottom: '10px' }}>
                <Box style={{ color: '#888' }}>
                  Owner: <span style={{ color: '#ffd700' }}>{owner_name}</span>
                </Box>
                <Box style={{ color: '#888' }}>
                  Location: {location_name}
                </Box>
                <Box style={{ color: '#4a90d9' }}>
                  Security: {securityName(security_level)}
                </Box>
                <Box style={{ color: '#888' }}>
                  Door:{' '}
                  <span
                    style={{ color: locked ? '#ff4444' : '#4cff4c' }}
                  >
                    {locked ? 'LOCKED' : 'UNLOCKED'}
                  </span>
                </Box>
              </Box>
              {is_authorized && (
                <Button
                  content={locked ? '[UNLOCK DOOR]' : '[LOCK DOOR]'}
                  color={locked ? 'good' : 'default'}
                  onClick={() => act('toggle_lock')}
                />
              )}
            </Section>

            {is_owner && (
              <>
                <Section title="> RENT STATUS">
                  <Box style={{ marginBottom: '10px' }}>
                    <Box style={{ color: rent_days_remaining > 3 ? '#4cff4c' : '#ff4444' }}>
                      {rent_days_remaining > 0
                        ? `${rent_days_remaining} days of rent remaining`
                        : 'RENT DUE - Pay now to keep your property!'}
                    </Box>
                    <Box style={{ color: '#ffd700' }}>
                      Weekly rent: {rent_cost} caps
                    </Box>
                  </Box>
                  <Flex align="center" style={{ marginBottom: '10px' }}>
                    <Box style={{ marginRight: '10px' }}>Weeks to pay:</Box>
                    <NumberInput
                      value={rentWeeks}
                      minValue={1}
                      maxValue={4}
                      step={1}
                      onChange={(e, value) => setRentWeeks(value)}
                    />
                  </Flex>
                  <Button
                    content={`[PAY ${rent_cost * rentWeeks} CAPS]`}
                    color="good"
                    onClick={() => act('pay_rent', { weeks: rentWeeks })}
                  />
                </Section>

                <Section title="> UPGRADES">
                  {security_level < 3 && (
                    <Flex justify="space-between" align="center" style={{ marginBottom: '10px' }}>
                      <Flex.Item>
                        <Box style={{ color: '#b8d4f0' }}>
                          Upgrade Security
                        </Box>
                        <Box style={{ color: '#888', fontSize: '0.85em' }}>
                          Cost: {upgrade_costs.security} caps
                        </Box>
                      </Flex.Item>
                      <Flex.Item>
                        <Button
                          content="[UPGRADE]"
                          onClick={() => act('upgrade_security')}
                        />
                      </Flex.Item>
                    </Flex>
                  )}
                  <Flex justify="space-between" align="center">
                    <Flex.Item>
                      <Box style={{ color: '#b8d4f0' }}>
                        Add Amenity
                      </Box>
                      <Box style={{ color: '#888', fontSize: '0.85em' }}>
                        Workbench, Bed, Storage, etc.
                      </Box>
                    </Flex.Item>
                    <Flex.Item>
                      <Button
                        content="[ADD]"
                        onClick={() => act('add_amenity', { amenity: 'workbench' })}
                      />
                    </Flex.Item>
                  </Flex>
                </Section>

                <Section title="> AUTHORIZED USERS">
                  <Box style={{ marginBottom: '10px' }}>
                    {authorized_users.length > 0 ? (
                      authorized_users.map((user) => (
                        <Flex key={user} justify="space-between" align="center" style={{ marginBottom: '5px' }}>
                          <Flex.Item style={{ color: '#b8d4f0' }}>{user}</Flex.Item>
                          <Flex.Item>
                            <Button
                              content="[REMOVE]"
                              color="bad"
                              onClick={() => act('remove_authorized', { ckey: user })}
                            />
                          </Flex.Item>
                        </Flex>
                      ))
                    ) : (
                      <Box style={{ color: '#666' }}>No authorized users.</Box>
                    )}
                  </Box>
                  <Flex align="center">
                    <Flex.Item grow={1} style={{ marginRight: '10px' }}>
                      <Input
                        fluid
                        placeholder="Enter player ckey..."
                        value={newUser}
                        onInput={(e, value) => setNewUser(value)}
                      />
                    </Flex.Item>
                    <Flex.Item>
                      <Button
                        content="[ADD]"
                        color="good"
                        onClick={() => {
                          act('add_authorized', { ckey: newUser });
                          setNewUser('');
                        }}
                      />
                    </Flex.Item>
                  </Flex>
                </Section>

                <Section title="> RELEASE PROPERTY">
                  <Box style={{ color: '#ff4444', marginBottom: '10px' }}>
                    Warning: This will release your ownership.
                    All items inside may be lost!
                  </Box>
                  <Button
                    content="[RELEASE OWNERSHIP]"
                    color="bad"
                    onClick={() => act('unclaim_house')}
                  />
                </Section>
              </>
            )}

            {!is_owner && (
              <Section title="> ACCESS">
                <Box style={{ color: is_authorized ? '#4cff4c' : '#ff4444' }}>
                  {is_authorized
                    ? 'You have authorized access to this property.'
                    : 'You do not have access to this property.'}
                </Box>
              </Section>
            )}
          </>
        )}

        <Box className="CharacterSetup__footer">
          WASTELAND PROPERTIES LLC
        </Box>
      </Window.Content>
    </Window>
  );
};
