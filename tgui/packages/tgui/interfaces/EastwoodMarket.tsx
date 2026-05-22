import { useBackend } from '../backend';
import { Button, Section, Table, Stack, NoticeBox, Flex, Box } from '../components';
import { Window } from '../layouts';

type EastwoodMarketData = {
  is_citizen?: boolean;
  market_open?: boolean;
  tax_rate?: number;
  tax_collected?: number;
  is_vendor?: boolean;
  vendor_type?: string;
  permit_paid?: boolean;
  permit_fee?: number;
  total_sales?: number;
  vendors?: Vendor[];
  stalls?: Stall[];
  trade_agreements?: TradeAgreement[];
};

type Vendor = {
  owner?: string;
  type?: string;
  paid?: boolean;
};

type Stall = {
  id?: string;
  rented?: boolean;
  daily_rate?: number;
};

type TradeAgreement = {
  faction?: string;
  active?: boolean;
  bonus?: number;
};

export const EastwoodMarket = (props, context) => {
  const { act, data } = useBackend<EastwoodMarketData>(context);

  const {
    is_citizen,
    market_open,
    tax_rate = 0.05,
    tax_collected = 0,
    is_vendor,
    vendor_type,
    permit_paid,
    permit_fee = 75,
    total_sales = 0,
    vendors = [],
    stalls = [],
    trade_agreements = [],
  } = data;

  const vendorTypes = ['general', 'weapons', 'medical'];

  return (
    <Window theme="fallout" width={600} height={650}>
      <Window.Content scrollable>
        <Stack vertical>
          <Section title="Eastwood Market">
            <Flex justify="space-between">
              {market_open ? (
                <NoticeBox info>Market is Open</NoticeBox>
              ) : (
                <NoticeBox warning>Market is Closed</NoticeBox>
              )}
            </Flex>
            <Box mt={1}>Tax Rate: {(tax_rate * 100).toFixed(0)}%</Box>
            <Box>Taxes Collected: {tax_collected} caps</Box>
          </Section>

          <Section title="Vendor Registration">
            {!is_vendor ? (
              <Flex direction="column" gap="5px">
                <Box>Select your vendor type:</Box>
                {vendorTypes.map(type => (
                  <Button
                    key={type}
                    onClick={() => act('register_vendor', { vendor_type: type })}
                  >
                    Register as{' '}
                    {type.charAt(0).toUpperCase() + type.slice(1)} Vendor
                  </Button>
                ))}
              </Flex>
            ) : (
              <Stack vertical>
                <NoticeBox success>
                  Registered as {vendor_type} vendor.
                </NoticeBox>
                {!permit_paid ? (
                  <Flex direction="column" gap="5px">
                    <Box>Permit Fee: {permit_fee} caps</Box>
                    <Button onClick={() => act('pay_permit')}>
                      Pay Permit Fee
                    </Button>
                  </Flex>
                ) : (
                  <NoticeBox success>Permit paid. You may operate.</NoticeBox>
                )}
                <Box>Total Sales: {total_sales} caps</Box>
              </Stack>
            )}
          </Section>

          <Section title="Market Stalls">
            <Table>
              <Table.Row header>
                <Table.Cell>Stall</Table.Cell>
                <Table.Cell>Status</Table.Cell>
                <Table.Cell>Daily Rate</Table.Cell>
                <Table.Cell>Actions</Table.Cell>
              </Table.Row>
              {stalls.map(stall => (
                <Table.Row key={stall.id}>
                  <Table.Cell>{stall.id}</Table.Cell>
                  <Table.Cell>{stall.rented ? 'Occupied' : 'Available'}</Table.Cell>
                  <Table.Cell>{stall.daily_rate} caps</Table.Cell>
                  <Table.Cell>
                    {!stall.rented && permit_paid && (
                      <Button onClick={() => act('rent_stall', { stall_id: stall.id })}>
                        Rent
                      </Button>
                    )}
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>

          <Section title="Registered Vendors">
            <Table>
              <Table.Row header>
                <Table.Cell>Name</Table.Cell>
                <Table.Cell>Type</Table.Cell>
                <Table.Cell>Status</Table.Cell>
              </Table.Row>
              {vendors.map(vendor => (
                <Table.Row key={vendor.owner}>
                  <Table.Cell>{vendor.owner}</Table.Cell>
                  <Table.Cell>{vendor.type}</Table.Cell>
                  <Table.Cell>{vendor.paid ? 'Active' : 'Unpaid'}</Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>

          <Section title="Trade Agreements">
            <Table>
              <Table.Row header>
                <Table.Cell>Faction</Table.Cell>
                <Table.Cell>Status</Table.Cell>
                <Table.Cell>Trade Bonus</Table.Cell>
              </Table.Row>
              {trade_agreements.map(agreement => (
                <Table.Row key={agreement.faction}>
                  <Table.Cell>{agreement.faction}</Table.Cell>
                  <Table.Cell>{agreement.active ? 'Active' : 'Inactive'}</Table.Cell>
                  <Table.Cell>
                    {((agreement.bonus || 0) * 100).toFixed(0)}%
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>
        </Stack>
      </Window.Content>
    </Window>
  );
};
