# 네일뭐해 빌드 스크립트: nail-mohae-v4.jsx -> index.html, nailmohae.html
# 사용법 (PowerShell, 프로젝트 폴더에서):  powershell -ExecutionPolicy Bypass -File .\build.ps1
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$jsx = [IO.File]::ReadAllText((Join-Path $here 'nail-mohae-v4.jsx'), $utf8)

# 1) import 문 제거 (파일 맨 앞의 react / lucide-react import 블록)
$marker = "// @app-start"
$i = $jsx.IndexOf($marker)
if ($i -lt 0) { throw "소스에서 '$marker' 를 찾지 못했습니다." }
$body = $jsx.Substring($i)
# 2) export default 제거
$body = $body.Replace('export default function App()', 'function App()')
if ($body -match '(?m)^\s*(import|export)\s') { throw 'import/export 문이 남아 있습니다.' }
if ($body -match '</script') { throw "소스에 '</script' 문자열이 있어 HTML에 넣을 수 없습니다." }

# 3) React 훅 + 이모지 아이콘 shim (lucide-react 대체)
$shim = @'
const { useState, useId, useEffect, useRef } = React;

function makeIcon(emoji) {
  return function Icon({ className, style }) {
    return React.createElement('span', { 'aria-hidden': 'true', className, style: { display: 'inline-flex', alignItems: 'center', justifyContent: 'center', lineHeight: 1, ...style } }, emoji);
  };
}
const Search = makeIcon('\u{1F50D}');
const User = makeIcon('\u{1F464}');
const Calendar = makeIcon('\u{1F4C5}');
const CheckCircle = makeIcon('✅');
const AlertTriangle = makeIcon('⚠️');
const X = makeIcon('✕');
const ChevronLeft = makeIcon('‹');
const MapPin = makeIcon('\u{1F4CD}');
const ShieldCheck = makeIcon('\u{1F6E1}️');
const Bell = makeIcon('\u{1F514}');
const PlusCircle = makeIcon('➕');
const ChevronDown = makeIcon('⌄');
const Flame = makeIcon('\u{1F525}');
const Wallet = makeIcon('\u{1F45B}');
const Package = makeIcon('\u{1F4E6}');
const BarChart3 = makeIcon('\u{1F4CA}');
const Megaphone = makeIcon('\u{1F4E3}');
const Trash2 = makeIcon('\u{1F5D1}️');
const EyeOff = makeIcon('\u{1F648}');
const Eye = makeIcon('\u{1F441}️');
const Landmark = makeIcon('\u{1F3DB}️');
const Store = makeIcon('\u{1F3EC}');
function Heart({ className, style }) {
  const filled = style && style.fill === '#f43f5e';
  return React.createElement('span', { 'aria-hidden': 'true', className, style: { display: 'inline-flex', alignItems: 'center', justifyContent: 'center', lineHeight: 1 } }, filled ? '❤️' : '\u{1F90D}');
}

'@

$head = @'
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover" />
<meta name="description" content="순천 네일샵 디자인 둘러보기·예약 플랫폼, 네일뭐해" />
<meta name="theme-color" content="#C77C8A" />
<title>네일뭐해 - 순천 네일샵 예약 플랫폼</title>
<script src="https://cdn.tailwindcss.com/3.4.17"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/react/18.3.1/umd/react.production.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/react-dom/18.3.1/umd/react-dom.production.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/babel-standalone/7.25.0/babel.min.js"></script>
<style>
  body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, "Apple SD Gothic Neo", "Malgun Gothic", sans-serif; word-break: keep-all; overflow-wrap: break-word; }
</style>
</head>
<body>
<div id="root"></div>
<noscript>네일뭐해를 이용하려면 자바스크립트를 켜주세요.</noscript>

<script type="text/plain" id="app-source">
'@

$tail = @'
</script>

<script>
  (function () {
    try {
      var source = document.getElementById('app-source').textContent;
      var output = Babel.transform(source, {
        presets: [['react', { runtime: 'classic' }]]
      }).code;
      output += '\nReactDOM.createRoot(document.getElementById("root")).render(React.createElement(App));';
      var script = document.createElement('script');
      script.textContent = output;
      document.body.appendChild(script);
    } catch (e) {
      document.getElementById('root').innerHTML = '<p style="padding:24px;font-size:14px">앱을 불러오지 못했어요. 새로고침해 주세요.</p>';
      console.error(e);
    }
  })();
</script>
</body>
</html>
'@

$out = ($head + "`n" + $shim + "`n" + $body.TrimEnd() + "`n" + $tail).Replace("`r`n", "`n")
[IO.File]::WriteAllText((Join-Path $here 'index.html'), $out, $utf8)
[IO.File]::WriteAllText((Join-Path $here 'nailmohae.html'), $out, $utf8)
Write-Host "빌드 완료: index.html, nailmohae.html ($($out.Length) chars)"
