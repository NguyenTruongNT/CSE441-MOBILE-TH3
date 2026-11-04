// Requires: npm install --prefix .dart_tool/ui-review playwright
// Start backend on :8080 and serve build/web on :8910 first.
const {chromium} = require('../.dart_tool/ui-review/node_modules/playwright');
const fs = require('fs');
const path = require('path');
const assert = require('assert');

(async () => {
  const root = path.resolve(__dirname, '..');
  const fixture = path.join(root, 'backend/pronunciation/.runtime/reference-tts.wav');
  assert(fs.existsSync(fixture), 'Create the local TTS smoke fixture first.');
  const output = path.resolve(root, process.env.UI_REVIEW_OUTPUT || 'screenshots/final');
  fs.mkdirSync(output, {recursive:true});
  const browser = await chromium.launch({
    executablePath: process.env.CHROME_PATH || 'C:/Program Files/Google/Chrome/Application/chrome.exe',
    headless: true,
    args: ['--use-fake-device-for-media-stream','--use-fake-ui-for-media-stream',`--use-file-for-fake-audio-capture=${fixture}`],
  });
  const context = await browser.newContext({viewport:{width:1366,height:1000},permissions:['microphone']});
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  const snapshot = async name => page.screenshot({path:path.join(output, `${name}.png`)});
  const openLogin = async () => {
    await page.goto('http://127.0.0.1:8910', {waitUntil:'domcontentloaded'});
    await page.waitForTimeout(4500);
    const placeholder=page.locator('flt-semantics-placeholder');
    if (await placeholder.count()) await placeholder.evaluate(element=>element.click());
    await page.getByRole('button',{name:/Học viên 1/}).waitFor();
  };
  const choose = async number => {
    await page.getByRole('button',{name:new RegExp(`Học viên ${number}`)}).click();
    await page.waitForTimeout(1000);
  };
  const navigate = async name => {
    await page.getByRole('button',{name,exact:true}).first().click();
    await page.waitForTimeout(650);
  };
  const semanticText = text => page.getByText(text,{exact:false}).or(page.getByLabel(text,{exact:false})).first();
  try {
    const health=await context.request.get('http://127.0.0.1:8080/health');
    assert((await health.json()).assessmentReady, 'Backend models must be ready before testing.');
    await openLogin();
    await snapshot('login-desktop');
    await choose(1);
    await snapshot('progress-desktop');
    await page.getByRole('button',{name:'Thu gọn thanh bên'}).click();
    await page.waitForTimeout(350); await snapshot('sidebar-collapsed');
    await page.getByRole('button',{name:'Mở rộng thanh bên'}).click();
    await page.waitForTimeout(350);
    await navigate('Luyện nói');
    await snapshot('catalog-desktop');
    const search=page.getByRole('textbox',{name:/Tìm bài luyện/});
    await search.click();
    await page.waitForTimeout(250);
    await page.keyboard.type('ship',{delay:60});
    await page.waitForTimeout(400);
    const sheep=page.getByRole('button',{name:'Mở bài luyện: The sheep on the ship looks big and neat',exact:true});
    await sheep.click();
    await page.getByRole('button',{name:'Danh sách bài luyện',exact:true}).waitFor();
    await search.waitFor({state:'hidden'});
    await page.getByRole('button',{name:'Danh sách bài luyện',exact:true}).click();
    await page.waitForTimeout(450);
    await search.click();
    await page.waitForTimeout(250);
    assert.equal(await search.inputValue(),'ship','Back should retain the search.');
    await search.click();
    await page.keyboard.press('ControlOrMeta+A');
    await page.keyboard.press('Backspace');
    await page.waitForTimeout(400);
    await page.getByRole('button',{name:'Mở bài luyện: I think this method is great',exact:true}).click();
    await page.waitForTimeout(450);
    await snapshot('practice-desktop');
    await page.getByRole('button',{name:'Bắt đầu ghi âm',exact:true}).click();
    await page.waitForTimeout(2900);
    const responsePromise=page.waitForResponse(response=>response.url().includes('/api/pronounce/analyze') && response.request().method()==='POST',{timeout:125000});
    await page.getByRole('button',{name:'Dừng & Phân tích',exact:true}).click();
    const response=await responsePromise;
    const assessment=await response.json();
    assert.equal(response.status(),200, JSON.stringify(assessment));
    assert(assessment.provider==='wav2vec2-phoneme-edit-similarity');
    assert(assessment.phonemes.length>0);
    await page.waitForTimeout(1000);
    const saved=page.getByText('Đã lưu kết quả',{exact:true});
    assert(await saved.count(), 'Result was not saved to SQLite.');
    await saved.scrollIntoViewIfNeeded(); await snapshot('assessment-desktop');
    await navigate('Lịch sử');
    await page.getByRole('button',{name:'Xem chi tiết',exact:true}).waitFor();
    await semanticText('I think this method is great').waitFor();
    await snapshot('history-desktop');
    await openLogin(); await choose(1); await navigate('Lịch sử');
    await page.getByRole('button',{name:'Xem chi tiết',exact:true}).waitFor();
    await semanticText('I think this method is great').waitFor();
    await snapshot('history-after-reload');
    const account=page.getByRole('button',{name:/Tài khoản/});
    if (await account.count()) await account.last().click();
    else await page.getByRole('button',{name:'Học viên 1',exact:true}).last().click();
    await page.waitForTimeout(300);
    await page.getByRole('button',{name:'Đăng xuất',exact:true}).last().click();
    await page.waitForTimeout(700); await choose(2); await navigate('Lịch sử');
    await semanticText('Chưa có phiên luyện tập').waitFor();
    assert.equal(await page.getByRole('button',{name:'Xem chi tiết',exact:true}).count(),0, 'History leaked to another account.');
    await snapshot('second-account-empty');
    await page.setViewportSize({width:360,height:900});
    await openLogin(); await snapshot('login-mobile'); await choose(1);
    await snapshot('progress-mobile'); await navigate('Luyện nói'); await snapshot('catalog-mobile');
    await page.getByRole('button',{name:'Mở bài luyện: I think this method is great',exact:true}).click();
    await page.waitForTimeout(450); await snapshot('practice-mobile');
    const mic=await page.getByRole('button',{name:'Luyện nói',exact:true}).boundingBox();
    assert(Math.abs(mic.x+mic.width/2-180)<12, 'Mobile practice button is not centered.');
    assert.deepEqual(errors, [], 'Browser page errors occurred.');
    const report={syntheticAudioOnly:true, realHumanEvaluation:false,
      verified:['catalog before practice','lesson selection','back preserves search','model API','microphone capture','SQLite save','history after reload','account isolation','desktop sidebar toggle','mobile centered practice navigation'],
      assessment:{score:assessment.overallScore,transcript:assessment.recognizedText,phones:assessment.phonemes.length,
        processingSeconds:assessment.processingSeconds,modelVersion:assessment.modelVersion},pageErrors:errors};
    fs.writeFileSync(path.join(output,'verification.json'),JSON.stringify(report,null,2));
    console.log(JSON.stringify(report));
  } catch(error) {
    await snapshot('failure');
    fs.writeFileSync(path.join(output,'failure-semantics.txt'),await page.locator('body').innerHTML());
    throw error;
  } finally { await context.close(); await browser.close(); }
})().catch(error=>{console.error(error);process.exit(1);});
