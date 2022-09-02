## PMC IF
```wavedrom
{signal: [
    {name: 'clk50',     wave: 'P......', period: 2 },
    {name: 'clk50p90',  wave: 'lHlHlHlHlHlHlH' },
    {name: 'sram adr',  wave: 'x.2.x.2.x', data: ['A1','A2'] },
    {name: 'sram dat',  wave: 'x..2.x.2.x', data: ['D1','D2'] },
    {name: 'tx dq buf', wave: 'x...2...2...x.', data: ['D1','D2'] },
    {name: 'clk',       wave: 'P.............', period: 1 },
    {name: 'phy dq',    wave: 'x....45554555x', data: ['D1',' ',' ',' ','D2',' ',' ',' '] }
]}
```

## 32b to 8b gearbox
```wavedrom
{signal: [
    {name: 'clk50',		wave: 'P....', period: 2 },
    {name: 'strobe',	wave: 'x.1.0.x...' },
    {name: 'din',		wave: 'x.2.x.....', data: ['D'] },
    {name: 'r1',		wave: 'x...2.x...', data: ['D[31:16]'] },
    {name: 'r2',		wave: 'x...2.2.xx', data: ['D[15:0]', 'D:[31:16]'] },
    {name: 'clk',		wave: 'P.........', period: 1 },
    {name: 'dout',		wave: 'x....2222x', data: ['1','2','3','4'] }
]}
```


