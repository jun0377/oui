<template>
  <div class="sim-page">
    <el-card class="sim-panel">
      <div class="sim-hero">
        <div class="sim-metric-title">{{ settings.alias }}</div>
        <div class="sim-metric-subtitle">{{ settings.interface || '-' }}</div>
      </div>

        <el-tabs v-model="simTab" type="border-card" class="sim-detail-tabs">
          <!-- Tab 1: 实时状态 -->
          <el-tab-pane label="实时状态" name="status" lazy>
            <div class="status-tab-content">
              <el-card class="config-card compact-card connection-card">
                <template #header>
                  <div class="card-header">
                    <span class="sim-card-title">{{ $t('连接状态') }}</span>
                  </div>
                </template>

                <div class="status-info">
                  <div class="status-item">
                    <span class="status-label"> 状态 :</span>
                    <span class="status-value"><span :class="getStatusClass()">{{ getStatusText() }}</span></span>
                  </div>

                  <div class="status-item">
                    <span class="status-label">{{ $t('状态更新时间') }}:</span>
                    <span class="status-value">{{ statusTimeText }}</span>
                  </div>

                  <div class="status-item">
                    <span class="status-label">{{ $t('网络接入技术') }}:</span>
                    <span class="status-value">{{ status.rat === 'NOSERVICE' ? '无服务' : status.rat }}</span>
                  </div>

                  <div class="status-item">
                    <span class="status-label">{{ $t('Real Band') }}:</span>
                    <span class="status-value">{{ getRealBandTypeText() }}</span>
                  </div>

                  <div class="signal-row signal-row-right" v-if="String(status.rat).toUpperCase() !== 'LTE'">
                    <div class="signal-title">5G信号强度:</div>
                    <template v-if="isNoService">
                      <span class="status-value">无服务</span>
                    </template>
                    <template v-else>
                      <div class="signal-item">
                        <span class="status-label">rsrp:</span>
                        <span class="signal-badge" :class="getSignalColor(status.nr.rsrp, 'rsrp')">{{ status.nr.rsrp || '-' }}</span>
                      </div>
                      <div class="signal-item">
                        <span class="status-label">rsrq:</span>
                        <span class="signal-badge" :class="getSignalColor(status.nr.rsrq, 'rsrq')">{{ status.nr.rsrq || '-' }}</span>
                      </div>
                      <div class="signal-item">
                        <span class="status-label">sinr:</span>
                        <span class="signal-badge" :class="getSignalColor(status.nr.sinr, 'sinr')">{{ status.nr.sinr || '-' }}</span>
                      </div>
                    </template>
                  </div>

                  <div class="signal-row signal-row-right" v-if="['NSA', 'LTE'].includes(String(status.rat).toUpperCase())">
                    <div class="signal-title">LTE信号:</div>
                    <template v-if="isNoService">
                      <span class="status-value">无服务</span>
                    </template>
                    <template v-else>
                      <div class="signal-item">
                        <span class="status-label">rsrp:</span>
                        <span class="signal-badge" :class="getSignalColor(status.lte.rsrp, 'rsrp')">{{ status.lte.rsrp || '-' }}</span>
                      </div>
                      <div class="signal-item">
                        <span class="status-label">rsrq:</span>
                        <span class="signal-badge" :class="getSignalColor(status.lte.rsrq, 'rsrq')">{{ status.lte.rsrq || '-' }}</span>
                      </div>
                      <div class="signal-item">
                        <span class="status-label">rssi:</span>
                        <span class="signal-badge" :class="getSignalColor(status.lte.rssi, 'rssi')">{{ status.lte.rssi || '-' }}</span>
                      </div>
                      <div class="signal-item">
                        <span class="status-label">sinr:</span>
                        <span class="signal-badge" :class="getSignalColor(status.lte.sinr, 'sinr')">{{ status.lte.sinr || '-' }}</span>
                      </div>
                    </template>
                  </div>

                  <div class="signal-row signal-row-right">
                    <div class="signal-title">数据统计:</div>
                    <div class="signal-item">
                      <span class="status-label">发送:</span>
                      <span class="status-value">{{ formatBytes(status.interface.txBytes) }}</span>
                    </div>
                    <div class="signal-item">
                      <span class="status-label">接收:</span>
                      <span class="status-value">{{ formatBytes(status.interface.rxBytes) }}</span>
                    </div>
                  </div>

                  <div class="status-item">
                    <span class="status-label">{{ $t('IP Address') }}:</span>
                    <span class="status-value">{{ status.interface.ip }}</span>
                  </div>

                  <div class="status-item">
                    <span class="status-label">{{ $t('Netmask') }}:</span>
                    <span class="status-value">{{ status.interface.mask }}</span>
                  </div>

                  <div class="status-item">
                    <span class="status-label">{{ $t('Gateway') }}:</span>
                    <span class="status-value">{{ status.interface.gateway }}</span>
                  </div>

                  <div class="status-item">
                    <span class="status-label">{{ $t('MAC') }}:</span>
                    <span class="status-value">{{ status.interface.mac }}</span>
                  </div>
                </div>
              </el-card>

              <div class="status-side-col">
                <el-card class="config-card compact-card">
                  <template #header>
                    <div class="card-header">
                      <span class="sim-card-title">{{ $t('SIM卡状态') }}</span>
                    </div>
                  </template>

                  <div class="status-info">
                    <div class="status-item">
                      <span class="status-label">状态:</span>
                      <span class="status-value">{{ formatSimStatus(sim.status) }}</span>
                    </div>
                    <div class="status-item">
                      <span class="status-label">{{ $t('Operator') }}:</span>
                      <span class="status-value">{{ sim.mcc }}{{ sim.mnc }} {{ formatSimOperator(sim.operator) }}</span>
                    </div>
                    <div class="status-item">
                      <span class="status-label">{{ $t('IMSI') }}:</span>
                      <span class="status-value">{{ productInfo.imsi }}</span>
                    </div>
                    <div class="status-item">
                      <span class="status-label">{{ $t('ICCID') }}:</span>
                      <span class="status-value">{{ productInfo.iccid }}</span>
                    </div>
                  </div>
                </el-card>

                <el-card class="config-card compact-card">
                  <template #header>
                    <div class="card-header">
                      <span class="sim-card-title">{{ $t('模组信息') }}</span>
                    </div>
                  </template>

                  <div class="status-info">
                    <div class="status-item">
                      <span class="status-label">模组型号:</span>
                      <span class="status-value">{{ productInfo.product }}</span>
                    </div>
                    <div class="status-item">
                      <span class="status-label">{{ $t('模组版本') }}:</span>
                      <span class="status-value">{{ productInfo.revision }}</span>
                    </div>
                    <div class="status-item">
                      <span class="status-label">{{ $t('IMEI') }}:</span>
                      <span class="status-value">{{ productInfo.imei }}</span>
                    </div>
                  </div>
                </el-card>

                <el-card class="config-card compact-card resident-card">
                  <template #header>
                    <div class="card-header">
                      <span class="sim-card-title">{{ $t('当前驻留小区') }}{{ isNoService ? '-无服务' : monsc.cell.type === 'nr' ? '-NR(5G)' : monsc.cell.type === 'lte' ? '-LTE' : '' }}</span>
                    </div>
                  </template>

                  <div class="status-table">
                    <div class="no-data" v-if="isNoService">
                      无服务
                    </div>
                    <div class="no-data" v-else-if="!monsc.cell.arfcn">
                      {{ $t('暂无数据') }}
                    </div>
                    <template v-if="monsc.cell.arfcn">
                      <div class="table-row header-row">
                        <div class="table-cell"><div class="cell-zh">频点</div><div class="cell-en">ARFCN</div></div>
                        <div class="table-cell" v-if="monsc.cell.type === 'nr'"><div class="cell-zh">子载波间隔</div><div class="cell-en">SCS</div></div>
                        <div class="table-cell"><div class="cell-zh">小区标识</div><div class="cell-en">Cell_ID</div></div>
                        <div class="table-cell"><div class="cell-zh">物理小区ID</div><div class="cell-en">PCI</div></div>
                        <div class="table-cell"><div class="cell-zh">跟踪区码</div><div class="cell-en">TAC</div></div>
                        <div class="table-cell"><div class="cell-zh">信号强度</div><div class="cell-en">RSRP/dBm</div></div>
                        <div class="table-cell"><div class="cell-zh">信号质量</div><div class="cell-en">RSRQ/dB</div></div>
                        <div class="table-cell" v-if="monsc.cell.type === 'nr'"><div class="cell-zh">信号与干扰比</div><div class="cell-en">SINR/dBm</div></div>
                        <div class="table-cell" v-if="monsc.cell.type === 'lte'"><div class="cell-zh">接收信号强度</div><div class="cell-en">RSSI/dBm</div></div>
                      </div>
                      <div class="table-row">
                        <div class="table-cell">{{ monsc.cell.arfcn }}</div>
                        <div class="table-cell" v-if="monsc.cell.type === 'nr'">{{ monsc.cell.scs }}</div>
                        <div class="table-cell">{{ monsc.cell.cell_id }}</div>
                        <div class="table-cell">{{ monsc.cell.pci }}<span class="cell-sub">({{ parseInt(monsc.cell.pci, 16) || '-' }})</span></div>
                        <div class="table-cell">{{ monsc.cell.tac }}</div>
                        <div class="table-cell"><span class="signal-badge" :class="getSignalColor(monsc.cell.rsrp, 'rsrp')">{{ monsc.cell.rsrp || '-' }}</span></div>
                        <div class="table-cell"><span class="signal-badge" :class="getSignalColor(monsc.cell.rsrq, 'rsrq')">{{ monsc.cell.rsrq || '-' }}</span></div>
                        <div class="table-cell" v-if="monsc.cell.type === 'nr'"><span class="signal-badge" :class="getSignalColor(monsc.cell.sinr, 'sinr')">{{ monsc.cell.sinr || '-' }}</span></div>
                        <div class="table-cell" v-if="monsc.cell.type === 'lte'"><span class="signal-badge" :class="getSignalColor(monsc.cell.rssi, 'rssi')">{{ monsc.cell.rssi || '-' }}</span></div>
                      </div>
                    </template>
                  </div>
                </el-card>
              </div>

              <div class="status-card-grid">
                <el-card class="config-card compact-card">
                  <template #header>
                    <div class="card-header">
                      <span class="sim-card-title">{{ $t('5G锁频/锁小区状态') }}</span>
                    </div>
                  </template>
                  <div class="status-info">
                    <div class="status-item">
                      <span class="status-label">锁状态:</span>
                      <span class="status-value">{{ getFreqLockTypeText(realSettings.nrfreqlock.operatetype) }}</span>
                    </div>
                    <div class="status-item">
                      <span class="status-label">频段:</span>
                      <span class="status-value">{{ realSettings.nrfreqlock.band.map(v => 'n' + v).join(', ') }}</span>
                    </div>
                    <div class="status-item">
                      <span class="status-label">频点:</span>
                      <span class="status-value">{{ realSettings.nrfreqlock.arfcn.join(', ') }}</span>
                    </div>
                    <div class="status-item">
                      <span class="status-label">SCS:</span>
                      <span class="status-value">{{ realSettings.nrfreqlock.scstype.join(', ') }}</span>
                    </div>
                    <div class="status-item">
                      <span class="status-label">PCI:</span>
                      <span class="status-value">{{ realSettings.nrfreqlock.pci.join(', ') }}</span>
                    </div>
                  </div>
                </el-card>

                <el-card class="config-card compact-card">
                  <template #header>
                    <div class="card-header">
                      <span class="sim-card-title">{{ $t('LTE锁频/锁小区状态') }}</span>
                    </div>
                  </template>
                  <div class="status-info">
                    <div class="status-item">
                      <span class="status-label">锁状态:</span>
                      <span class="status-value">{{ getFreqLockTypeText(realSettings.ltefreqlock.operatetype) }}</span>
                    </div>
                    <div class="status-item">
                      <span class="status-label">频段:</span>
                      <span class="status-value">{{ realSettings.ltefreqlock.band.map(v => 'b' + v).join(',') }}</span>
                    </div>
                    <div class="status-item">
                      <span class="status-label">频点:</span>
                      <span class="status-value">{{ realSettings.ltefreqlock.arfcn.join(', ') }}</span>
                    </div>
                    <div class="status-item">
                      <span class="status-label">PCI:</span>
                      <span class="status-value">{{ realSettings.ltefreqlock.pci.join(', ') }}</span>
                    </div>
                  </div>
                </el-card>
              </div>

              <!-- AT日志终端: 置于实时状态页右下角 -->
              <el-card class="config-card compact-card at-log-card">
                <div class="at-log-terminal" ref="atLogTerminal" @scroll="handleAtLogScroll">
                  <div v-if="atLogs.length === 0" class="at-log-empty">暂无AT指令日志</div>
                  <div
                    v-for="(entry, idx) in atLogs"
                    :key="entry.seq || `gap-${idx}`"
                    v-show="!atLogErrorOnly || (entry.kind !== 'gap' && cleanAtLogRes(entry).indexOf('OK') === -1)"
                    class="at-log-entry"
                    :class="{ 'is-gap': entry.kind === 'gap' }"
                  >
                    <template v-if="entry.kind === 'gap'">
                      <div class="at-log-gap">{{ entry.message }}</div>
                    </template>
                    <template v-else>
                      <div class="at-log-entry-head">#{{ entry.seq }} {{ entry.ts || '-' }} {{ entry.tty || '-' }} : {{ entry.cmd }}</div>
                      <pre class="at-log-line at-log-res" :class="getAtLogResultClass(cleanAtLogRes(entry))">{{ cleanAtLogRes(entry) }}</pre>
                    </template>
                  </div>
                </div>
                <div class="at-log-actions">
                  <el-button size="small" :type="atLogErrorOnly ? 'danger' : 'default'" @click="atLogErrorOnly = !atLogErrorOnly">
                    {{ atLogErrorOnly ? '显示全部' : '只看错误' }}
                  </el-button>
                </div>
              </el-card>

              <!-- Action buttons -->
              <div class="action-buttons status-tab-actions">
                <el-button @click="goBack" type="info" size="large">{{ $t('Back') }}</el-button>
              </div>
            </div>
          </el-tab-pane>

          <!-- Tab 2: 基本设置 -->
          <el-tab-pane label="基本设置" name="basic" lazy>
            <el-form :model="settings" label-width="90px" class="config-form basic-form" label-align="left" label-position="left">
                <el-form-item :label="$t('Network Access')">
                  <el-select v-model="settings.net" :placeholder="$t('Select access type')" class="sim-full-width">
                    <el-option :label="$t('AUTO')" value="AUTO"/>
                    <el-option label="SA" value="SA"/>
                    <el-option label="NSA" value="NSA"/>
                    <el-option label="LTE" value="LTE"/>
                  </el-select>
                </el-form-item>

                <el-form-item :label="$t('Authentication')">
                  <el-select v-model="settings.auth" :placeholder="$t('Select auth type')" class="sim-full-width">
                    <el-option :label="$t('AUTO')" value="AUTO"/>
                    <el-option label="PAP" value="PAP"/>
                    <el-option label="CHAP" value="CHAP"/>
                    <el-option :label="$t('NONE')" value="none"/>
                  </el-select>
                </el-form-item>

                <el-form-item :label="$t('USER')">
                  <el-input v-model="settings.username" placeholder="Enter User name"/>
                </el-form-item>

                <el-form-item :label="$t('PASSWD')">
                  <el-input v-model="settings.password" placeholder="Enter User password"/>
                </el-form-item>

                <el-form-item label="APN">
                  <el-input v-model="settings.apn" placeholder="Enter APN"/>
                </el-form-item>
                <el-form-item :label="$t('Enable')">
                  <el-switch
                    :model-value="settings.enable"
                    @update:model-value="handleEnableChange"
                    inline-prompt
                    :active-text="'开'"
                    :inactive-text="'关'"
                    class="wan-enable-switch"
                  />
                </el-form-item>
              </el-form>

              <!-- Action buttons -->
              <div class="action-buttons card-actions">
                <el-button @click="saveConfig" type="primary" size="large">{{ $t('Save Configuration') }}</el-button>
                <el-button @click="resetConfig" type="warning" size="large" class="btn-disabled-warning">{{ $t('Reset to Default') }}</el-button>
                <el-button @click="goBack" type="info" size="large">{{ $t('Back') }}</el-button>
              </div>
          </el-tab-pane>

          <!-- Tab 3: 锁频段 -->
          <el-tab-pane label="频段设置" name="bandlock" lazy>
            <el-form :model="settings" label-width="90px" class="config-form" label-align="left" label-position="left">
                <el-form-item label="锁 NR 频段" class="sim-lock-form-item">
                  <div class="sim-lock-section">
                    <div class="sim-pci-row sim-lock-toolbar">
                      <el-tag
                        class="band-option-tag"
                        :type="!settings.nrBandLockEnabled ? 'primary' : 'info'"
                        :effect="!settings.nrBandLockEnabled ? 'dark' : 'plain'"
                        @click="handleNRBandToggle"
                      >
                        {{ settings.nrBandLockEnabled ? '解锁' : '未锁定,点击进行设置' }}
                      </el-tag>
                    </div>
                    <template v-if="settings.nrBandLockEnabled">
                      <div class="sim-band-panel">
                        <div v-if="getNRBandOptions().filter(o => o !== '解锁').length" class="band-option-list">
                          <el-tag
                            v-for="opt in getNRBandOptions().filter(o => o !== '解锁')"
                            :key="opt"
                            class="band-option-tag"
                            :type="isNRBandOptionActive(opt) ? 'primary' : 'info'"
                            :effect="isNRBandOptionActive(opt) ? 'dark' : 'plain'"
                            @click="selectNRBandOption(opt)"
                          >
                            {{ opt }}
                          </el-tag>
                        </div>
                        <div v-else class="band-option-empty">暂无可选频段</div>
                      </div>
                    </template>
                  </div>
                </el-form-item>

                <el-form-item label="锁 LTE 频段" class="sim-lock-form-item">
                  <div class="sim-lock-section">
                    <div class="sim-pci-row sim-lock-toolbar">
                      <el-tag
                        class="band-option-tag"
                        :type="!settings.lteBandLockEnabled ? 'primary' : 'info'"
                        :effect="!settings.lteBandLockEnabled ? 'dark' : 'plain'"
                        @click="handleLTEBandToggle"
                      >
                        {{ settings.lteBandLockEnabled ? '解锁' : '未锁定,点击进行设置' }}
                      </el-tag>
                    </div>
                    <template v-if="settings.lteBandLockEnabled">
                      <div class="sim-band-panel">
                        <div v-if="getLTEBandOptions().filter(o => o !== '解锁').length" class="band-option-list">
                          <el-tag
                            v-for="opt in getLTEBandOptions().filter(o => o !== '解锁')"
                            :key="opt"
                            class="band-option-tag"
                            :type="isLTEBandOptionActive(opt) ? 'primary' : 'info'"
                            :effect="isLTEBandOptionActive(opt) ? 'dark' : 'plain'"
                            @click="selectLTEBandOption(opt)"
                          >
                            {{ opt }}
                          </el-tag>
                        </div>
                        <div v-else class="band-option-empty">暂无可选频段</div>
                      </div>
                    </template>
                  </div>
                </el-form-item>
              </el-form>

              <!-- Action buttons -->
              <div class="action-buttons card-actions">
                <el-button @click="saveConfig" type="primary" size="large">{{ $t('Save Configuration') }}</el-button>
                <el-button @click="resetConfig" type="warning" size="large" class="btn-disabled-warning">{{ $t('Reset to Default') }}</el-button>
                <el-button @click="goBack" type="info" size="large">{{ $t('Back') }}</el-button>
              </div>
          </el-tab-pane>

          <!-- Tab 4: PCI小区设置(优选PCI小区 / 手动锁PCI小区) -->
          <el-tab-pane label="PCI小区设置" name="pcilock" lazy>
            <div class="pci-tab-grid">
              <el-card class="config-card">
              <template #header>
                <div class="card-header">
                  <span class="sim-card-title">PCI小区设置</span>
                </div>
              </template>
              <el-form :model="settings" label-width="90px" class="config-form" label-align="left" label-position="left">
                <el-form-item label="锁定方式" class="sim-lock-form-item">
                  <el-radio-group v-model="settings.pci_mode" size="small">
                    <el-tooltip
                      content="按驻留稳定性自动优选小区<br/>探测完成后锁定最优小区并重新拨号"
                      raw-content
                      effect="light"
                      popper-class="sim-prefer-tip-popper"
                      placement="top"
                    >
                      <el-radio-button value="prefer">自动优选小区</el-radio-button>
                    </el-tooltip>
                    <el-radio-button value="manual">手动锁小区</el-radio-button>
                  </el-radio-group>
                </el-form-item>

                <!-- 手动锁PCI小区: 显示 NR/LTE PCI 锁定配置 -->
                <template v-if="settings.pci_mode === 'manual'">
                  <el-form-item label="锁 NR PCI" class="sim-lock-form-item">
                    <div class="sim-lock-section">
                      <div class="sim-lock-head">
                        <el-switch :model-value="settings.nr_pci.enabled" size="small" @change="handleNRPciToggle"/>
                        <span class="sim-lock-head-text">{{ settings.nr_pci.enabled ? '已启用锁定' : '未启用, 打开开关后配置锁定条目' }}</span>
                      </div>

                      <template v-if="settings.nr_pci.enabled">
                        <div class="sim-pci-table">
                          <div class="sim-pci-col-head">
                            <span>PCID(十进制)</span>
                            <span>频点</span>
                            <span>频段</span>
                            <span>子载波间隔</span>
                            <span></span>
                          </div>
                          <div v-for="(entry, idx) in settings.nr_pci.items" :key="idx" class="sim-pci-entry-row">
                            <el-input v-model="entry.pcid" placeholder="PCID(十进制)" class="sim-pci-input" size="small" @change="handleNRPciInputChange(idx)"/>
                            <el-input v-model="entry.freq" placeholder="频点" class="sim-pci-input" size="small" @change="handleNRPciInputChange(idx)"/>
                            <el-select v-model="entry.band" placeholder="频段" class="sim-pci-input" size="small" @change="handleNRPciInputChange(idx)">
                              <el-option label="n1" value="1"/>
                              <el-option label="n3" value="3"/>
                              <el-option label="n5" value="5"/>
                              <el-option label="n8" value="8"/>
                              <el-option label="n28" value="28"/>
                              <el-option label="n41" value="41"/>
                              <el-option label="n78" value="78"/>
                            </el-select>
                            <el-select v-model="entry.scs" placeholder="子载波间隔" class="sim-pci-input" size="small" @change="handleNRPciInputChange(idx)">
                              <el-option label="15KHz" value="0"/>
                              <el-option label="30KHz" value="1"/>
                              <el-option label="60KHz" value="2"/>
                              <el-option label="120KHz" value="3"/>
                              <el-option label="240KHz" value="4"/>
                            </el-select>
                            <el-button link type="danger" class="sim-pci-remove-btn" @click="removeNRPciEntry(idx)">删除</el-button>
                          </div>
                        </div>

                        <div class="sim-pci-foot">
                          <el-button size="small" class="sim-pci-add-btn" @click="addNRPciEntry">添加条目</el-button>
                          <div class="sim-pci-foot-item">
                            <span class="sim-pci-foot-label">允许重选切换小区</span>
                            <el-switch v-model="settings.nr_pci.reSelEnabled" size="small"/>
                          </div>
                        </div>
                      </template>
                    </div>
                  </el-form-item>

                  <el-form-item label="锁 LTE PCI" class="sim-lock-form-item">
                    <div class="sim-lock-section">
                      <div class="sim-lock-head">
                        <el-switch :model-value="settings.lte_pci.enabled" size="small" @change="handleLtePciToggle"/>
                        <span class="sim-lock-head-text">{{ settings.lte_pci.enabled ? '已启用锁定' : '未启用, 打开开关后配置锁定条目' }}</span>
                      </div>

                      <template v-if="settings.lte_pci.enabled">
                        <div class="sim-pci-table is-lte">
                          <div class="sim-pci-col-head">
                            <span>PCID</span>
                            <span>频点</span>
                            <span>频段</span>
                            <span></span>
                          </div>
                          <div v-for="(entry, idx) in settings.lte_pci.items" :key="idx" class="sim-pci-entry-row">
                            <el-input v-model="entry.pcid" placeholder="PCID" class="sim-pci-input" size="small" @change="handleLtePciInputChange(idx)"/>
                            <el-input v-model="entry.freq" placeholder="频点" class="sim-pci-input" size="small" @change="handleLtePciInputChange(idx)"/>
                            <el-select v-model="entry.band" placeholder="频段" class="sim-pci-input" size="small" @change="handleLtePciInputChange(idx)">
                              <el-option label="b1" value="1"/>
                              <el-option label="b3" value="3"/>
                              <el-option label="b5" value="5"/>
                              <el-option label="b8" value="8"/>
                              <el-option label="b34" value="34"/>
                              <el-option label="b39" value="39"/>
                              <el-option label="b40" value="40"/>
                              <el-option label="b41" value="41"/>
                            </el-select>
                            <el-button link type="danger" class="sim-pci-remove-btn" @click="removeLtePciEntry(idx)">删除</el-button>
                          </div>
                        </div>

                        <div class="sim-pci-foot">
                          <el-button size="small" class="sim-pci-add-btn" @click="addLtePciEntry">添加条目</el-button>
                          <div class="sim-pci-foot-item">
                            <span class="sim-pci-foot-label">允许重选切换小区</span>
                            <el-switch v-model="settings.lte_pci.reSelEnabled" size="small"/>
                          </div>
                        </div>
                      </template>
                    </div>
                  </el-form-item>
                </template>

                <!-- 优选PCI小区: 由模组按信号质量自动选优小区 -->
                <template v-else>
                  <el-form-item label="优选策略" class="sim-lock-form-item">
                    <el-radio-group v-model="settings.pci_prefer.strategy" size="small">
                      <el-radio value="stability">按驻留稳定性</el-radio>
                    </el-radio-group>
                  </el-form-item>
                  <el-form-item label="超时时间" class="sim-lock-form-item">
                    <div class="sim-prefer-row">
                      <el-tooltip
                        content="探测时长(秒), 超时后按最优小区锁定"
                        effect="light"
                        popper-class="sim-prefer-tip-popper"
                        placement="top"
                      >
                        <el-input-number
                          v-model="settings.pci_prefer.timeout"
                          :min="30"
                          :max="300"
                          :step="30"
                          size="small"
                          controls-position="right"
                          class="sim-prefer-input"
                        />
                      </el-tooltip>
                      <span class="sim-prefer-hint">秒</span>
                    </div>
                  </el-form-item>
                  <el-form-item label="排除小区" class="sim-lock-form-item">
                    <div class="sim-prefer-col">
                      <div
                        v-for="(_pci, idx) in settings.pci_prefer.exclude_pcis"
                        :key="idx"
                        class="sim-prefer-row"
                      >
                        <el-tooltip
                          content="优选时忽略这些小区; 十进制 PCI(0-1007)"
                          effect="light"
                          popper-class="sim-prefer-tip-popper"
                          placement="top"
                        >
                          <el-input
                            v-model="settings.pci_prefer.exclude_pcis[idx]"
                            size="small"
                            placeholder="PCI(十进制)"
                            class="sim-prefer-input"
                            @change="handleExcludePciInputChange(idx)"
                          />
                        </el-tooltip>
                        <el-button
                          v-if="idx === settings.pci_prefer.exclude_pcis.length - 1"
                          size="small"
                          circle
                          type="primary"
                          class="sim-prefer-icon-btn"
                          @click="addExcludePciEntry"
                        >+</el-button>
                        <el-button
                          v-if="settings.pci_prefer.exclude_pcis.length > 1"
                          size="small"
                          circle
                          class="sim-prefer-icon-btn"
                          @click="removeExcludePciEntry(idx)"
                        >−</el-button>
                      </div>
                    </div>
                  </el-form-item>
                  <el-form-item class="sim-lock-form-item">
                    <div class="sim-prefer-row">
                      <el-tooltip
                        content="重新执行优先小区策略"
                        effect="light"
                        popper-class="sim-prefer-tip-popper"
                        placement="top"
                      >
                        <el-button size="small" type="primary" @click="handlePreferReselectNow">立即重选</el-button>
                      </el-tooltip>
                    </div>
                  </el-form-item>
                </template>
              </el-form>

              <!-- Action buttons -->
              <div class="action-buttons card-actions">
                <el-button @click="saveConfig" type="primary" size="large">{{ $t('Save Configuration') }}</el-button>
                <el-button @click="resetConfig" type="warning" size="large" class="btn-disabled-warning">{{ $t('Reset to Default') }}</el-button>
                <el-button @click="goBack" type="info" size="large">{{ $t('Back') }}</el-button>
              </div>
            </el-card>

            <div class="pci-side-col">
            <el-card v-if="settings.pci_mode === 'prefer'" class="config-card pci-prefer-card">
              <template #header>
                <div class="card-header">
                  <span class="sim-card-title">优选小区状态</span>
                </div>
              </template>

              <div class="status-info">
                <div class="status-item">
                  <span class="pci-prefer-status-group">
                    <span class="status-label">优选状态</span>
                    <span class="status-badge" :class="preferRunning ? 'status-badge-running' : (pciAutoSelect.enabled ? 'status-badge-done' : 'status-badge-disabled')">
                      {{ preferStatusText }}
                      <span v-if="preferRunning">剩余 {{ preferRemainSeconds }} 秒</span>
                    </span>
                  </span>
                </div>
                <div class="pci-prefer-subtitle">
                  <span>探测结果</span>
                  <span v-if="!preferRunning && preferDecisionText" class="pci-prefer-reason">{{ preferDecisionText }}</span>
                </div>
                <div
                  class="pci-prefer-result"
                  v-loading="preferRunning"
                  :element-loading-text="'探测中(第' + preferRound + '轮)...'"
                >
                  <div class="no-data" v-if="isNoService">
                    无服务
                  </div>
                  <div class="no-data" v-else-if="!monsc.cell.arfcn">
                    {{ $t('暂无数据') }}
                  </div>
                  <template v-else>
                    <div class="sim-cell-table">
                      <div class="table-row header-row">
                        <div class="table-cell"><div class="cell-zh">频点</div><div class="cell-en">ARFCN</div></div>
                        <div class="table-cell" v-if="monsc.cell.type === 'nr'"><div class="cell-zh">子载波间隔</div><div class="cell-en">SCS</div></div>
                        <div class="table-cell"><div class="cell-zh">小区标识</div><div class="cell-en">Cell_ID</div></div>
                        <div class="table-cell"><div class="cell-zh">物理小区ID</div><div class="cell-en">PCI</div></div>
                        <div class="table-cell"><div class="cell-zh">跟踪区码</div><div class="cell-en">TAC</div></div>
                        <div class="table-cell"><div class="cell-zh">信号强度</div><div class="cell-en">RSRP/dBm</div></div>
                        <div class="table-cell"><div class="cell-zh">信号质量</div><div class="cell-en">RSRQ/dB</div></div>
                        <div class="table-cell" v-if="monsc.cell.type === 'nr'"><div class="cell-zh">信号与干扰比</div><div class="cell-en">SINR/dB</div></div>
                        <div class="table-cell" v-if="monsc.cell.type === 'lte'"><div class="cell-zh">接收信号强度</div><div class="cell-en">RSSI/dBm</div></div>
                      </div>
                      <div class="table-row">
                        <div class="table-cell">{{ monsc.cell.arfcn }}</div>
                        <div class="table-cell" v-if="monsc.cell.type === 'nr'">{{ monsc.cell.scs }}</div>
                        <div class="table-cell">{{ monsc.cell.cell_id }}</div>
                        <div class="table-cell">{{ monsc.cell.pci }}<span class="cell-sub">({{ parseInt(monsc.cell.pci, 16) || '-' }})</span></div>
                        <div class="table-cell">{{ monsc.cell.tac }}</div>
                        <div class="table-cell"><span class="signal-badge" :class="getSignalColor(monsc.cell.rsrp, 'rsrp')">{{ monsc.cell.rsrp || '-' }}</span></div>
                        <div class="table-cell"><span class="signal-badge" :class="getSignalColor(monsc.cell.rsrq, 'rsrq')">{{ monsc.cell.rsrq || '-' }}</span></div>
                        <div class="table-cell" v-if="monsc.cell.type === 'nr'"><span class="signal-badge" :class="getSignalColor(monsc.cell.sinr, 'sinr')">{{ monsc.cell.sinr || '-' }}</span></div>
                        <div class="table-cell" v-if="monsc.cell.type === 'lte'"><span class="signal-badge" :class="getSignalColor(monsc.cell.rssi, 'rssi')">{{ monsc.cell.rssi || '-' }}</span></div>
                      </div>
                    </div>
                  </template>
                </div>
              </div>
            </el-card>

            <el-card class="config-card neighbor-card">
              <template #header>
                <div class="card-header">
                  <span class="sim-card-title">{{ $t('相邻小区信息') }}</span>
                </div>
              </template>

              <div class="status-table">
                <div class="no-data" v-if="isNoService">
                  无服务
                </div>
                <div class="no-data" v-else-if="!monnc.nr.length && !monnc.lte.length">
                  {{ $t('暂无数据') }}
                </div>
                <div class="table-title" v-if="monnc.nr.length">NR相邻小区</div>
                <div class="sim-cell-table" v-if="monnc.nr.length">
                  <div class="table-row header-row">
                    <div class="table-cell">ARFCN</div>
                    <div class="table-cell">PCI(十六进制)</div>
                    <div class="table-cell">PCI(十进制)</div>
                    <div class="table-cell">RSRP/dBm</div>
                    <div class="table-cell">RSRQ/dB</div>
                    <div class="table-cell">SINR/dBm</div>
                  </div>
                  <div class="table-row" v-for="(cell, index) in sortedNrCells" :key="'nr-' + index">
                    <div class="table-cell">{{ cell.arfcn }}</div>
                    <div class="table-cell">{{ cell.pci }}</div>
                    <div class="table-cell">{{ parseInt(cell.pci, 16) || '-' }}</div>
                    <div class="table-cell"><span class="signal-badge" :class="getSignalColor(cell.rsrp, 'rsrp')">{{ cell.rsrp || '-' }}</span></div>
                    <div class="table-cell"><span class="signal-badge" :class="getSignalColor(cell.rsrq, 'rsrq')">{{ cell.rsrq || '-' }}</span></div>
                    <div class="table-cell"><span class="signal-badge" :class="getSignalColor(cell.sinr, 'sinr')">{{ cell.sinr || '-' }}</span></div>
                  </div>
                </div>
                <div class="table-title" v-if="monnc.lte.length">LTE相邻小区</div>
                <div class="sim-cell-table" v-if="monnc.lte.length">
                  <div class="table-row header-row">
                    <div class="table-cell">ARFCN</div>
                    <div class="table-cell">PCI(十六进制)</div>
                    <div class="table-cell">PCI(十进制)</div>
                    <div class="table-cell">RSRP</div>
                    <div class="table-cell">RSRQ</div>
                    <div class="table-cell">RXLEV</div>
                  </div>
                  <div class="table-row" v-for="(cell, index) in sortedLteCells" :key="'lte-' + index">
                    <div class="table-cell">{{ cell.arfcn }}</div>
                    <div class="table-cell">{{ cell.pci }}</div>
                    <div class="table-cell">{{ parseInt(cell.pci, 16) || '-' }}</div>
                    <div class="table-cell"><span class="signal-badge" :class="getSignalColor(cell.rsrp, 'rsrp')">{{ cell.rsrp || '-' }}</span></div>
                    <div class="table-cell"><span class="signal-badge" :class="getSignalColor(cell.rsrq, 'rsrq')">{{ cell.rsrq || '-' }}</span></div>
                    <div class="table-cell"><span class="signal-badge" :class="getSignalColor(cell.rxlev, 'rssi')">{{ cell.rxlev || '-' }}</span></div>
                  </div>
                </div>
              </div>
            </el-card>
            </div>
            </div>
          </el-tab-pane>
        </el-tabs>
      </el-card>
    </div>
</template>

<script>
export default {
  name: 'sim-settings',
  emits: ['go-back'],
  props: {
    wanData: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      status: {
        status: '',
        timestamp: '',
        routerTime: '',
        rat: '-',
        nr: { rsrp: '', rsrq: '', sinr: '', band: '' },
        lte: { rsrp: '', rsrq: '', sinr: '', rssi: '', band: '' },
        interface: { ip: '-', mask: '-', gateway: '-', mac: '-', rxBytes: '-', txBytes: '-' }
      },
      productInfo: {
        vendor: '',
        product: '',
        revision: '',
        imei: '',
        iccid: '',
        imsi: ''
      },
      sim: {
        operator: '',
        status: '',
        mcc: '',
        mnc: ''
      },
      freqInfo: {
        sysmode: '',
        class: []
      },
      // NR注册状态
      NR_5GCore: {
        stat: '',
        tac: '',
        ci: '',
        act: ''
      },
      CS: {
        stat: '',
        lac: '',
        ci: '',
        act: ''
      },
      // 驻留小区信息
      monsc: {
        rat: '',
        mcc: '',
        mnc: '',
        cell: { type: '', arfcn: '', scs: '', cell_id: '', pci: '', tac: '', rsrp: '', rsrq: '', sinr: '', rssi: '' }
      },
      // 相邻小区信息
      monnc: {
        gsm: [],
        wcdma: [],
        lte: [],
        nr: []
      },
      realSettings: {
        rat: '',
        pdp: { cid: '', pdp_type: '', apn: '', pdp_addr: '' },
        auth: { cid: '', auth_type: '', passwd: '', username: '', plmn: '' },
        nrfreqlock: { operatetype: '', forbid_flag: '', num: '', band: [], arfcn: [], scstype: [], pci: [] },
        ltefreqlock: { operatetype: '', forbid_flag: '', num: '', band: [], arfcn: [], pci: [] }
      },
      settings: {
        index: '',
        enable: true,
        alias: '',
        name: '',
        interface: '',
        net: '',
        apn: '',
        nrBand: '',
        nrBandLockEnabled: false,
        nrBandUnLock: true,
        lteBand: '',
        lteBandLockEnabled: false,
        lteBandUnLock: true,
        nr_pci: { enabled: false, reSelEnabled: true, items: [{ enabled: false, pcid: '', band: '', freq: '', scs: '' }] },
        lte_pci: { enabled: false, reSelEnabled: true, items: [{ enabled: false, pcid: '', band: '', freq: '' }] },
        // PCI小区设置方式: prefer=优选PCI小区 / manual=手动锁PCI小区
        pci_mode: 'manual',
        // 优选PCI小区配置: 优选策略(rsrp=按信号强度 / stability=按驻留稳定性), 超时时间(秒), 排除的小区PCI(十进制)
        pci_prefer: { strategy: 'stability', timeout: 60, exclude_pcis: [''] },
        auth: '',
        username: '',
        password: ''
      },
      settingsInitialized: false,
      atLogs: [],
      pendingAtLogs: [],
      atLogEnabled: false,
      atLogErrorOnly: false,
      atLogSeq: 0,
      maxLogEntries: 200,
      atLogLoading: false,
      atLogAutoFollow: true,
      atLogDrainTimer: null,
      simTab: 'status',
      nowTick: 0,
      // 自动优选小区探测状态, 由后端 sim.getOverview 提供(剩余秒数/轮次/选优结果均由后端计算)
      pciAutoSelect: { enabled: false, running: false, remain: 0, round: 0, timeout: 0, reason: '', nr: null, lte: null },
      // 路由器与浏览器时钟偏移(ms), 在 routerTime 更新时校准并冻结
      clockOffset: 0,
      // 模组是否被系统识别(未安装模组 / 未上电时为 false)
      moduleExist: true
    }
  },
  created() {
    if (this.wanData)
      this.applyWanData(this.wanData)
    this.$timer.create('sim-at-logs', () => this.fetchAtLogs(), { time: 1000, repeat: true, autostart: false })
    // 每秒刷新相对时间显示
    this.$timer.create('sim-time-ago', () => {
      this.nowTick++
    }, { time: 1000, repeat: true })
    // AT日志终端常驻实时状态页, 默认开启拉取
    this.atLogEnabled = true
  },
  beforeUnmount() {
    this.$timer.stop('sim-at-logs')
    if (this.atLogDrainTimer) {
      clearTimeout(this.atLogDrainTimer)
      this.atLogDrainTimer = null
    }
  },
  watch: {
    atLogEnabled(val) {
      if (val) {
        this.atLogSeq = 0
        this.atLogs = []
        this.pendingAtLogs = []
        this.atLogAutoFollow = true
        this.$timer.start('sim-at-logs')
        this.fetchAtLogs()
      } else {
        this.$timer.stop('sim-at-logs')
        this.atLogs = []
        this.pendingAtLogs = []
        this.atLogSeq = 0
        this.atLogLoading = false
        this.atLogAutoFollow = true
        this.atLogErrorOnly = false
        if (this.atLogDrainTimer) {
          clearTimeout(this.atLogDrainTimer)
          this.atLogDrainTimer = null
        }
      }
    },
    wanData: {
      handler(newVal, oldVal) {
        if (!newVal)
          return
        if (!oldVal || (oldVal.settings && newVal.settings && oldVal.settings.index !== newVal.settings.index))
          this.settingsInitialized = false
        this.applyWanData(newVal)
      },
      immediate: true,
      deep: true
    },
    // 路由器当前时间更新时, 重新校准时钟偏移(冻结), 使相对时间每秒正常递增
    'status.routerTime'(val) {
      const routerMs = this.parseLocalTime(String(val))
      this.clockOffset = isNaN(routerMs) ? 0 : routerMs - Date.now()
    }
  },
  computed: {
    // 状态更新时间, 以相对时间(x秒前)显示, 每秒刷新
    statusTimeText() {
      this.nowTick
      return this.formatTimeAgo(this.status.timestamp)
    },
    isNoService() {
      return this.status && this.status.hcsq && this.status.hcsq.sysmode === 'NOSERVICE'
    },
    sortedNrCells() {
      const cells = this.monnc.nr || []
      return [...cells].sort((a, b) => {
        const va = parseFloat(a.rsrp)
        const vb = parseFloat(b.rsrp)
        if (isNaN(va) && isNaN(vb)) return 0
        if (isNaN(va)) return 1
        if (isNaN(vb)) return -1
        return vb - va
      })
    },
    sortedLteCells() {
      const cells = this.monnc.lte || []
      return [...cells].sort((a, b) => {
        const va = parseFloat(a.rsrp)
        const vb = parseFloat(b.rsrp)
        if (isNaN(va) && isNaN(vb)) return 0
        if (isNaN(va)) return 1
        if (isNaN(vb)) return -1
        return vb - va
      })
    },
    // 优选PCI小区: 状态文案(后端未开启自动优选时为未开启)
    preferStatusText() {
      if (this.pciAutoSelect.enabled !== true)
        return '未开启'
      return this.preferRunning ? '优选策略执行中' : '执行完毕'
    },
    // 优选PCI小区: 是否正在探测, 由后端探测状态给出
    preferRunning() {
      if (this.settings.pci_mode !== 'prefer')
        return false
      return this.pciAutoSelect.running === true
    },
    // 优选PCI小区: 剩余探测秒数(由后端探测文件中的开始时间与超时时间推算)
    preferRemainSeconds() {
      if (this.settings.pci_mode !== 'prefer')
        return 0
      return Math.max(0, Number(this.pciAutoSelect.remain) || 0)
    },
    // 优选PCI小区: 已探测轮次(由后端探测文件统计)
    preferRound() {
      return Math.max(1, Number(this.pciAutoSelect.round) || 0)
    },
    // 优选PCI小区: 决策原因, 由后端统计选优后给出
    preferDecisionText() {
      return this.pciAutoSelect.reason || ''
    }
  },
  methods: {
    formatBytes(bytes) {
      const n = Number(bytes)
      if (!Number.isFinite(n) || n < 0)
        return '-'
      if (n >= 1024 * 1024 * 1024)
        return `${(n / 1024 / 1024 / 1024).toFixed(2)} GB`
      if (n >= 1024 * 1024)
        return `${(n / 1024 / 1024).toFixed(2)} MB`
      if (n >= 1024)
        return `${(n / 1024).toFixed(2)} KB`
      return `${n} B`
    },
    // 信号值强度颜色
    getSignalColor(val, type) {
      const v = parseFloat(val)
      if (!Number.isFinite(v)) return 'sig-empty'
      if (type === 'rsrp') {
        if (v >= -80) return 'sig-excellent'
        if (v >= -90) return 'sig-good'
        if (v >= -100) return 'sig-fair'
        return 'sig-poor'
      }
      if (type === 'rsrq') {
        if (v >= -10) return 'sig-excellent'
        if (v >= -15) return 'sig-good'
        if (v >= -20) return 'sig-fair'
        return 'sig-poor'
      }
      if (type === 'sinr') {
        if (v >= 20) return 'sig-excellent'
        if (v >= 13) return 'sig-good'
        if (v >= 0) return 'sig-fair'
        return 'sig-poor'
      }
      if (type === 'rssi') {
        if (v >= -65) return 'sig-excellent'
        if (v >= -75) return 'sig-good'
        if (v >= -85) return 'sig-fair'
        return 'sig-poor'
      }
      return 'sig-empty'
    },
    // sim卡状态可读性优化
    formatSimStatus(status) {
      const raw = String(status ?? '').trim()
      if (!raw)
        return '-'
      if (/[\u4e00-\u9fa5]/.test(raw))
        return raw

      const normalized = raw.toLowerCase()
      const mappings = [
        { match: ['not inserted', 'sim removed'], text: '未插卡' },
        { match: ['puk locked'], text: '卡被锁' },
        { match: ['initializing'], text: '初始化中' },
        { match: ['network service available'], text: '初始化成功,可接入网络' },
        { match: ['pbm and sms access'], text: '初始化成功,可拨打电话' }
      ]

      for (const item of mappings) {
        if (item.match.some(keyword => normalized.includes(keyword)))
          return item.text
      }

      return raw
    },
    // 运营商信息高可读性
    formatSimOperator(operator) {
      const raw = String(operator ?? '').trim()
      if (!raw)
        return '-'
      if (/[\u4e00-\u9fa5]/.test(raw))
        return raw

      const normalized = raw.toLowerCase()
      const mappings = [
        { match: ['china mobile', 'cmcc'], text: '中国移动' },
        { match: ['china unicom', 'cucc', 'unicom'], text: '中国联通' },
        { match: ['china telecom', 'ctcc', 'telecom'], text: '中国电信' },
        { match: ['broadnet', 'cbn'], text: '中国广电' }
      ]

      for (const item of mappings) {
        if (item.match.some(keyword => normalized.includes(keyword)))
          return item.text
      }

      return raw
    },
    getFreqLockTypeText(type) {
      const map = { '0': '解锁状态', '1': '锁频点+锁频段', '2': '锁小区+频点+锁频段', '3': '锁频段' }
      return map[type] || type
    },
    getRealBandTypeText() {
      const fi = this.freqInfo
      if (!fi)
        return ''
      const sysmode = String(fi.sysmode ?? '').trim().toUpperCase()
      let isNr = false
      let isLte = false
      if (sysmode.includes('NR')) isNr = true
      else if (sysmode.includes('LTE')) isLte = true
      else if (sysmode === '7') isNr = true
      else if (sysmode === '3') isLte = true
      if (!isNr && !isLte) {
        const rat = String(this.status?.rat ?? '').toUpperCase()
        if (rat.includes('LTE')) isLte = true
        else if (rat.includes('NR')) isNr = true
      }
      const list = Array.isArray(fi.class) ? fi.class : []
      const seen = new Set()
      const prefix = isNr ? 'n' : 'b'
      const bands = []
      for (const item of list) {
        const bandClass = item && item.band_class !== null ? String(item.band_class).trim() : ''
        if (!bandClass || seen.has(bandClass))
          continue
        seen.add(bandClass)
        bands.push(prefix + bandClass)
      }
      return bands.join(' ')
    },
    getNRBandOptions() {
      return ['解锁', 'n1', 'n3', 'n5', 'n8', 'n28', 'n41', 'n78', 'n79']
    },
    getLTEBandOptions() {
      return ['解锁', 'b1', 'b3', 'b5', 'b8', 'b34', 'b38', 'b39', 'b40', 'b41']
    },
    applyWanData(data) {
      if (!data)
        return
      this.status = data.status
      this.productInfo = data.productInfo
      // 模组是否被系统识别(父级通过 sim.getOverview 同步到 wanData)
      if (typeof data.moduleExist === 'boolean')
        this.moduleExist = data.moduleExist
      this.sim = data.sim
      this.freqInfo = data.freqInfo
      this.NR_5GCore = data.NR_5GCore
      this.CS = data.CS
      this.monsc = data.monsc
      this.monnc = data.monnc
      // 自动优选小区探测状态(父级通过 sim.getOverview 同步到 wanData)
      this.pciAutoSelect = data.pciAutoSelect || { enabled: false, running: false, remain: 0, round: 0, timeout: 0, reason: '', nr: null, lte: null }
      this.realSettings = data.realSettings
      if (!this.settingsInitialized) {
        this.settings.index = data.settings.index
        this.settings.enable = typeof data.settings.enable === 'boolean' ? data.settings.enable : true
        this.settings.ifname = data.settings.ifname
        this.settings.alias = data.settings.alias
        this.settings.interface = data.settings.interface
        this.settings.net = String(data.settings.net || '').toUpperCase()
        this.settings.apn = data.settings.apn
        this.settings.band = data.settings.band || data.settings.settingsBand || ''
        this.settings.auth = data.settings.auth
        this.settings.username = data.settings.username
        this.settings.password = data.settings.password
        const bandTokens = String(this.settings.band || '').split(',').map(item => item.trim()).filter(Boolean)
        const nrStoredBand = bandTokens.find(item => item.toLowerCase().startsWith('n')) || ''
        const lteStoredBand = bandTokens.find(item => item.toLowerCase().startsWith('b')) || ''
        const nrRealBand = data.realSettings && data.realSettings.nrfreqlock && Array.isArray(data.realSettings.nrfreqlock.band) ? (data.realSettings.nrfreqlock.band[0] || '') : ''
        const lteRealBand = data.realSettings && data.realSettings.ltefreqlock && Array.isArray(data.realSettings.ltefreqlock.band) ? (data.realSettings.ltefreqlock.band[0] || '') : ''
        this.settings.nrBand = nrRealBand || nrStoredBand
        this.settings.lteBand = lteRealBand || lteStoredBand
        this.settings.nrBandUnLock = (this.settings.nrBand === 'unlocked' || this.settings.nrBand === 'none' || this.settings.nrBand === '')
        this.settings.lteBandUnLock = (this.settings.lteBand === 'unlocked' || this.settings.lteBand === 'none' || this.settings.lteBand === '')
        this.settings.nrBandLockEnabled = !this.settings.nrBandUnLock
        this.settings.lteBandLockEnabled = !this.settings.lteBandUnLock
        if (this.settings.nrBandUnLock)
          this.settings.nrBand = 'unlocked'
        if (this.settings.lteBandUnLock)
          this.settings.lteBand = 'unlocked'
        this.settings.pci = data.settings.pcid || data.settings.settingsPCI
        this.settings.pciUnlock = (this.settings.pci === 'none' || this.settings.pci === '')
        if (data.settings.nr_pci) {
          this.settings.nr_pci = data.settings.nr_pci
        }
        // PCI小区设置方式: UCI pciAutoSelect=1 表示自动优选小区
        const autoSelect = data.settings.pciAutoSelect
        this.settings.pci_mode = (autoSelect === '1' || autoSelect === 'true' || autoSelect === 1 || autoSelect === true) ? 'prefer' : 'manual'
        this.settings.pci_prefer.strategy = 'stability'
        const preferTimeout = Number(data.settings.pciAutoSelectTimeout)
        this.settings.pci_prefer.timeout = Number.isFinite(preferTimeout) && preferTimeout > 0 ? Math.floor(preferTimeout) : 60
        // 排除列表: UCI中的000为占位符, 过滤后为空时保留一个空输入框
        const excludeRaw = data.settings.pciAutoSelectExclude
        const excludeList = (Array.isArray(excludeRaw) ? excludeRaw : (excludeRaw === undefined || excludeRaw === null ? [] : [excludeRaw]))
          .map(item => String(item).trim())
          .filter(item => item !== '' && item !== '000')
        this.settings.pci_prefer.exclude_pcis = excludeList.length ? excludeList : ['']
        this.settingsInitialized = true
      }
    },
    goBack() {
      this.$emit('go-back', { refresh: true })
    },
    isAtLogNearBottom() {
      const el = this.$refs.atLogTerminal
      if (!el)
        return true
      const threshold = 24
      return el.scrollTop + el.clientHeight >= el.scrollHeight - threshold
    },
    scrollAtLogToBottom() {
      this.$nextTick(() => {
        requestAnimationFrame(() => {
          const el = this.$refs.atLogTerminal
          if (el)
            el.scrollTop = el.scrollHeight
        })
      })
    },
    handleAtLogScroll() {
      this.atLogAutoFollow = this.isAtLogNearBottom()
    },
    normalizeAtLogResponse(result) {
      if (!result)
        return null
      if (typeof result === 'string') {
        try {
          return JSON.parse(result)
        } catch {
          return null
        }
      }
      return result
    },
    cleanAtLogRes(entry) {
      if (!entry || !entry.res) return ''
      const cmd = String(entry.cmd || '')
      const lines = String(entry.res).split('\n')
      // 跳过首行如果它等于 AT 指令（回显）
      const start = lines[0] && lines[0].trim() === cmd.trim() ? 1 : 0
      return lines.slice(start).filter(l => l !== '').join('\n')
    },
    getAtLogDrainDelay() {
      const pending = this.pendingAtLogs.length
      if (this.atLogs.length === 0)
        return 12
      if (pending > 40)
        return 12
      if (pending > 20)
        return 20
      if (pending > 8)
        return 35
      return 70
    },
    scheduleAtLogDrain() {
      if (!this.atLogEnabled || this.atLogDrainTimer || this.pendingAtLogs.length === 0)
        return
      this.atLogDrainTimer = setTimeout(() => {
        this.atLogDrainTimer = null
        this.drainAtLogEntry()
      }, this.getAtLogDrainDelay())
    },
    drainAtLogEntry() {
      if (!this.atLogEnabled || this.pendingAtLogs.length === 0)
        return
      const shouldFollow = this.atLogAutoFollow || this.isAtLogNearBottom() || this.atLogs.length === 0
      // cold start: dump all pending at once to jump to end
      if (this.atLogs.length === 0 && this.pendingAtLogs.length > 10) {
        this.atLogs.push(...this.pendingAtLogs.splice(0))
      } else {
        const nextEntry = this.pendingAtLogs.shift()
        this.atLogs.push(nextEntry)
      }
      this.trimAtLogs()
      if (shouldFollow)
        this.scrollAtLogToBottom()
      if (this.pendingAtLogs.length > 0)
        this.scheduleAtLogDrain()
    },
    enqueueAtLogs(entries) {
      if (!Array.isArray(entries) || entries.length === 0)
        return
      this.pendingAtLogs.push(...entries)
      this.scheduleAtLogDrain()
    },
    getAtLogResultClass(res) {
      const text = String(res ?? '')
      if (text.includes('+CME ERROR:') || /(^|\n)ERROR(\n|$)/.test(text))
        return 'is-err'
      if (/(^|\n)OK(\n|$)/.test(text))
        return 'is-ok'
      return ''
    },
    appendAtLogGapNotice(earliestSeq) {
      const message = earliestSeq > 0
        ? `日志存在缺口，当前仅保留 seq >= ${earliestSeq} 的 AT 指令记录`
        : '日志存在缺口，部分较早的 AT 指令记录已不可用'
      const last = this.pendingAtLogs[this.pendingAtLogs.length - 1] || this.atLogs[this.atLogs.length - 1]
      if (last && last.kind === 'gap' && last.message === message)
        return
      this.enqueueAtLogs([{
        kind: 'gap',
        seq: `gap-${Date.now()}-${earliestSeq}`,
        message
      }])
    },
    trimAtLogs() {
      if (this.atLogs.length > this.maxLogEntries)
        this.atLogs.splice(0, this.atLogs.length - this.maxLogEntries)
    },
    fetchAtLogs() {
      if (!this.atLogEnabled || this.atLogLoading) return
      const ifname = this.settings.ifname || this.settings.alias
      if (!ifname) return
      this.atLogLoading = true
      const afterSeq = this.atLogSeq
      const limit = afterSeq > 0 ? 80 : this.maxLogEntries
      let shouldContinue = false
      this.$oui.call('sim', 'getAtLogs', { ifname, after_seq: afterSeq, limit }).then(raw => {
        const result = this.normalizeAtLogResponse(raw)
        if (!result)
          return

        if (result.gap && afterSeq > 0)
          this.appendAtLogGapNotice(Number(result.earliest_seq) || 0)

        const entries = Array.isArray(result.entries) ? result.entries : []
        if (entries.length > 0) {
          this.atLogSeq = Number(result.next_seq) || this.atLogSeq
          this.enqueueAtLogs(entries)
        }

        shouldContinue = Boolean(result.has_more) && this.atLogEnabled
      }).catch(() => {
      }).finally(() => {
        this.atLogLoading = false
        if (shouldContinue)
          this.fetchAtLogs()
      })
    },
    addNRPciEntry() {
      if (this.settings.nr_pci.items.length >= 20) {
        this.$message.warning('最多允许20个条目')
        return
      }
      this.settings.nr_pci.items.push({ enabled: false, pcid: '', band: '', freq: '', scs: '' })
    },
    removeNRPciEntry(idx) {
      if (this.settings.nr_pci.items.length > 1) {
        this.settings.nr_pci.items.splice(idx, 1)
      } else {
        this.$message.warning('无法删除唯一的条目')
      }
    },
    // 链路使能
    handleEnableChange(enabled) {
      if (!enabled) {
        this.$confirm('关闭后将断开蜂窝链路，是否确认关闭？', '提示', {
          confirmButtonText: '确认',
          cancelButtonText: '取消',
          type: 'warning'
        }).then(() => {
          this.applyEnableChange(false)
        }).catch(() => {
          // 用户取消，开关保持原状
        })
      } else {
        this.applyEnableChange(true)
      }
    },
    applyEnableChange(enabled) {
      this.settings.enable = enabled
      if (!enabled) {
        if (this.status && this.status.interface) {
          this.status.interface.ip = ''
          this.status.interface.mask = ''
          this.status.interface.gateway = ''
        }
        this.status.rat = ''
        if (this.freqInfo) {
          this.freqInfo.class = []
        }
      }

      // console.log('handleEnableChange called, enabled:', enabled, 'settings:', JSON.stringify(this.settings))

      this.$oui.call('sim', 'changeSimEnable', this.settings).then((response) => {
        if (response === 0)
          this.$message[enabled ? 'success' : 'warning'](enabled ? '已开启' : '已关闭')
        else
          this.$message.error('设置失败')
      }).catch(() => {
        this.$message.error('设置失败')
      })
    },
    // 当前状态字符串
    getStatusText() {
      if (!this.settings.enable)
        return '已禁用'
      // 模组是否被系统识别(未安装模组或模组未上电)
      if (this.moduleExist === false)
        return '模组不存在'
      if (this.isNoService)
        return '无服务'
      // 判断是否有IP,有IP则返回'在线'
      if (this.status && this.status.interface && this.status.interface.ip)
        return '在线'
      if (!this.NR_5GCore.stat && !this.CS.stat)
        return '离线'
      let stat = ''
      if (this.NR_5GCore.stat !== '')
        stat = stat + 'NR' + this.NR_5GCore.stat
      if (this.CS.stat !== '') {
        if (stat !== '')
          stat = stat + ' | '
        stat = stat + 'LTE' + this.CS.stat
      }
      return stat
    },
    // 当前状态对应的徽章样式
    getStatusClass() {
      const text = this.getStatusText()
      if (text === '已禁用')
        return 'status-badge status-badge-disabled'
      if (text === '模组不存在')
        return 'status-badge status-badge-nomodule'
      if (text === '无服务')
        return 'status-badge status-badge-noservice'
      if (text === '在线')
        return 'status-badge status-badge-online'
      if (text === '离线')
        return 'status-badge status-badge-offline'
      return 'status-badge status-badge-info'
    },
    // 将本地格式时间字符串解析为时间戳(毫秒), 按浏览器本地时区解释
    parseLocalTime(str) {
      const full = str.match(/^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})/)
      if (full) {
        const [, y, mo, d, h, mi, s] = full
        return new Date(+y, +mo - 1, +d, +h, +mi, +s).getTime()
      }
      // 仅时间格式: HH:MM:SS (视为当天)
      const parts = str.split(':').map(Number)
      if (parts.length === 3 && !parts.some(n => isNaN(n))) {
        const now = new Date()
        const base = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()
        return base + (parts[0] * 3600 + parts[1] * 60 + parts[2]) * 1000
      }
      return NaN
    },
    // 将 "YYYY-MM-DD HH:MM:SS" 或 "HH:MM:SS" 格式的时间戳转为 "x秒前"
    // 时钟偏移在 routerTime 更新时由 watcher 校准并冻结, 保证每秒正常递增
    formatTimeAgo(ts) {
      if (!ts)
        return '-'
      const text = String(ts).trim()
      let tsMs = this.parseLocalTime(text)
      if (isNaN(tsMs))
        return text
      // 纯时间格式跨天时往前推一天
      if (tsMs > Date.now() + this.clockOffset)
        tsMs -= 24 * 3600 * 1000
      const diffSec = Math.max(0, Math.floor((Date.now() + this.clockOffset - tsMs) / 1000))
      return `${diffSec}秒前`
    },
    // 保存配置
    saveConfig() {
      if (!this.settings.interface) {
        this.$message.error('The network interface must be specified!')
        return
      }
      // 优选PCI小区模式下由模组自动选优, 不做手动锁定的参数校验
      const isManualPciMode = this.settings.pci_mode !== 'prefer'
      if (isManualPciMode && this.settings.nr_pci && this.settings.nr_pci.enabled && !this.settings.nrBandUnLock) {
        this.$message.error('锁NR频段和锁NR PCI不允许同时设置，请先解锁其中一个')
        return
      }
      const nrPciEntries = isManualPciMode ? this.settings.nr_pci.items.filter(e => e.enabled) : []
      for (const e of nrPciEntries) {
        if (!e.pcid || !e.band || !e.freq || e.scs === '') {
          this.$message.error('请完整填写NR PCI锁定参数: PCID/频段/频点/子载波间隔')
          return
        }
      }
      if (isManualPciMode && this.settings.lte_pci && this.settings.lte_pci.enabled && !this.settings.lteBandUnLock) {
        this.$message.error('锁LTE频段和锁LTE PCI不允许同时设置，请先解锁其中一个')
        return
      }
      const ltePciEntries = isManualPciMode ? this.settings.lte_pci.items.filter(e => e.enabled) : []
      for (const e of ltePciEntries) {
        if (!e.pcid || !e.band || !e.freq) {
          this.$message.error('请完整填写LTE PCI锁定参数: PCID/频段/频点')
          return
        }
      }
      if (!this.settings.pciUnlock && ('none' === this.settings.pci || '' === this.settings.pci)) {
        this.$message.error('请设置小区PCID 或 解锁小区!')
        return
      }
      const payload = {
        ...this.settings,
        nr_pci: {
          ...this.settings.nr_pci,
          enabled: isManualPciMode && this.settings.nr_pci.enabled,
          items: nrPciEntries.map(e => ({
            enabled: true,
            pcid: String(e.pcid),
            band: String(e.band),
            freq: String(e.freq),
            scs: String(e.scs)
          }))
        },
        lte_pci: {
          ...this.settings.lte_pci,
          enabled: isManualPciMode && this.settings.lte_pci.enabled,
          items: ltePciEntries.map(e => ({
            enabled: true,
            pcid: String(e.pcid),
            band: String(e.band),
            freq: String(e.freq)
          }))
        }
      }
      this.$oui.call('sim', 'changeSimSettings', payload).then((response) => {
        if (response && response.code === 0)
          this.$message.success('设置成功')
      })
    },
    resetConfig() {
      this.$confirm(this.$t('Are you sure to reset to default configuration?'), this.$t('Confirm Reset'), { type: 'warning' }).then(() => {
        this.settings.enable = true
        this.settings.net = 'AUTO'
        this.settings.auth = 'none'
        this.settings.username = 'user'
        this.settings.password = 'passwd'
        this.settings.apn = 'cmnet'
        this.settings.nrBand = 'unlocked'
        this.settings.nrBandUnLock = true
        this.settings.nrBandLockEnabled = false
        this.settings.lteBand = 'unlocked'
        this.settings.lteBandUnLock = true
        this.settings.lteBandLockEnabled = false
        this.settings.nr_pci = { enabled: false, reSelEnabled: true, items: [{ enabled: false, pcid: '', band: '', freq: '', scs: '' }] }
        this.settings.lte_pci = { enabled: false, reSelEnabled: true, items: [{ enabled: false, pcid: '', band: '', freq: '' }] }
        this.settings.pci_mode = 'manual'
        this.settings.pci_prefer = { strategy: 'stability', timeout: 60, exclude_pcis: [''] }
        this.$oui.call('sim', 'changeSimSettings', this.settings).then((response) => {
          if (response && response.code === 0) {
            this.$oui.call('sim', 'changeSimEnable', this.settings).then((res) => {
              if (res === 0) {
                this.$message.success(this.$t('Configuration reset successfully'))
              }
            })
          }
        })
      })
    },
    // 优选PCI小区: 立即重选, 由后端复位探测结果并重新探测优选, 期间会重新拨号, 需二次确认
    handlePreferReselectNow() {
      this.$confirm('立即重选将重新执行一轮优选探测, 期间会重新拨号并短暂断网, 是否继续？', '立即重选', {
        confirmButtonText: '确认',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        const ifname = this.settings.ifname || this.settings.alias
        if (!ifname) {
          this.$message.error('立即重选失败')
          return
        }
        this.$oui.call('sim', 'pciAutoSelectReselect', { ifname }).then((res) => {
          if (res === 0)
            this.$message.success('已触发立即重选')
          else
            this.$message.error('立即重选失败')
        }).catch(() => {
          this.$message.error('立即重选失败')
        })
      }).catch(() => {
        // 用户取消, 不改变当前优选状态
      })
    },
    // 优选PCI小区: 排除小区列表的增删与校验
    addExcludePciEntry() {
      this.settings.pci_prefer.exclude_pcis.push('')
    },
    removeExcludePciEntry(idx) {
      this.settings.pci_prefer.exclude_pcis.splice(idx, 1)
    },
    // 仅接受 0-1007 的十进制 PCI, 自动去重
    handleExcludePciInputChange(idx) {
      const list = this.settings.pci_prefer.exclude_pcis
      const digits = String(list[idx] === undefined || list[idx] === null ? '' : list[idx]).replace(/\D/g, '')
      if (digits === '') {
        list[idx] = ''
        return
      }
      const pcid = parseInt(digits, 10)
      if (pcid > 1007) {
        this.$message.warning('PCI 范围为 0-1007, 请重新输入')
        list[idx] = ''
        return
      }
      if (list.some((item, i) => i !== idx && String(item) === String(pcid))) {
        this.$message.warning('该 PCI 已存在, 请勿重复添加')
        list[idx] = ''
        return
      }
      list[idx] = String(pcid)
    },
    handleNRPciToggle() {
      if (this.settings.nr_pci.enabled) {
        this.handleNRPciUnlock()
      } else {
        this.settings.nr_pci.enabled = true
      }
    },
    handleNRBandToggle() {
      if (this.settings.nrBandLockEnabled) {
        this.selectNRBandOption('解锁')
      } else {
        this.settings.nrBandLockEnabled = true
      }
    },
    handleLTEBandToggle() {
      if (this.settings.lteBandLockEnabled) {
        this.selectLTEBandOption('解锁')
      } else {
        this.settings.lteBandLockEnabled = true
      }
    },
    handleNRPciUnlock() {
      this.settings.nr_pci.enabled = false
      this.settings.nr_pci.items.forEach(e => {
        e.enabled = false
        e.pcid = ''
        e.band = ''
        e.freq = ''
        e.scs = ''
      })
    },
    handleNRPciInputChange(idx) {
      this.settings.nr_pci.enabled = true
      this.settings.nr_pci.items[idx].enabled = true
    },
    handleLtePciToggle() {
      if (this.settings.lte_pci.enabled) {
        this.handleLtePciUnlock()
      } else {
        this.settings.lte_pci.enabled = true
      }
    },
    handleLtePciUnlock() {
      this.settings.lte_pci.enabled = false
      this.settings.lte_pci.items.forEach(e => {
        e.enabled = false
        e.pcid = ''
        e.band = ''
        e.freq = ''
      })
    },
    handleLtePciInputChange(idx) {
      this.settings.lte_pci.enabled = true
      this.settings.lte_pci.items[idx].enabled = true
    },
    addLtePciEntry() {
      if (this.settings.lte_pci.items.length >= 20) {
        this.$message.warning('最多允许20个条目')
        return
      }
      this.settings.lte_pci.items.push({ enabled: false, pcid: '', band: '', freq: '' })
    },
    removeLtePciEntry(idx) {
      if (this.settings.lte_pci.items.length > 1) {
        this.settings.lte_pci.items.splice(idx, 1)
      } else {
        this.$message.warning('无法删除唯一的条目')
      }
    },
    selectNRBandOption(value) {
      if (value === '解锁') {
        this.settings.nrBand = 'unlocked'
        this.settings.nrBandUnLock = true
        this.settings.nrBandLockEnabled = false
        return
      }
      this.settings.nrBand = value
      this.settings.nrBandUnLock = false
      this.settings.nrBandLockEnabled = true
    },
    selectLTEBandOption(value) {
      if (value === '解锁') {
        this.settings.lteBand = 'unlocked'
        this.settings.lteBandUnLock = true
        this.settings.lteBandLockEnabled = false
        return
      }
      this.settings.lteBand = value
      this.settings.lteBandUnLock = false
      this.settings.lteBandLockEnabled = true
    },
    isNRBandOptionActive(value) {
      if (value === '解锁')
        return this.settings.nrBandUnLock || this.settings.nrBand === ''
      return !this.settings.nrBandUnLock && this.settings.nrBand === value
    },
    isLTEBandOptionActive(value) {
      if (value === '解锁')
        return this.settings.lteBandUnLock || this.settings.lteBand === ''
      return !this.settings.lteBandUnLock && this.settings.lteBand === value
    }
  }
}
</script>

<style scoped>
.sim-page {
  max-width: 1600px;
  margin: 0 auto;
  padding: 16px;

  /* 本地设计 token: 圆角/间距/字号/边框统一取值, 避免逐处硬编码 */
  --status-value-col-width: 10ch;
  --sim-radius: 8px;
  --sim-radius-sm: 6px;
  --sim-gap: 12px;
  --sim-font-title: 16px;
  --sim-font-base: 14px;
  --sim-font-label: 13px;
  --sim-font-minor: 12px;
  --sim-font-xs: 11px;
  --sim-border: 1px solid var(--el-border-color-lighter);
}

/* 页面容器: 仅作承载, 不设圆角/边框/阴影 */
.sim-panel {
  width: 100%;
  border: 0;
  border-radius: 0;
  box-shadow: none;
}

/* ---- el-tabs 样式(与 management-tabs 统一) ---- */
.sim-detail-tabs {
  border-radius: var(--sim-radius);
  overflow: hidden;
}

.sim-detail-tabs :deep(.el-tabs__header) {
  background-color: var(--el-fill-color-light);
}

.sim-detail-tabs :deep(.el-tabs__item) {
  font-weight: 600;
  font-size: var(--sim-font-base);
}

:deep(.sim-panel .el-card__body) {
  padding: 0;
}

/* 模组标题条: 标题与网口名同行, 靠下边框分隔, 不做渐变/彩边/投影 */
.sim-hero {
  display: flex;
  align-items: baseline;
  gap: 10px;
  margin-bottom: var(--sim-gap);
  padding: 0 4px 10px;
  border-bottom: var(--sim-border);
}

.sim-metric-title {
  font-size: var(--sim-font-title);
  font-weight: 600;
  color: var(--el-text-color-primary);
  line-height: 1.2;
}

.sim-metric-subtitle {
  font-size: var(--sim-font-label);
  color: var(--el-text-color-secondary);
  word-break: break-word;
}

/* 实时状态 tab: 2列网格布局 */
.status-tab-content {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--sim-gap);
  align-items: start;
}

.status-card-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: var(--sim-gap);
  grid-column: 1;
  /* 与右侧AT日志卡片等高 */
  align-self: stretch;
}

.status-side-col {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--sim-gap);
}

/* 实时状态 tab 底部操作行(横跨两列) */
.status-tab-actions {
  grid-column: 1 / -1;
  padding-top: 4px;
}

/* 底部返回按钮长度放大两倍 */
.status-tab-actions .el-button {
  min-width: 180px;
}

.resident-card {
  grid-column: span 2;
}

/* PCI小区设置 tab: 左设置/右状态 两栏布局 */
.pci-tab-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--sim-gap);
  align-items: start;
}

/* PCI设置卡内的操作按钮与表单拉开间距 */
.pci-tab-grid .config-card .action-buttons {
  margin-top: 16px;
}

/* PCI小区设置 tab 右列: 优选项状态卡片 + 相邻小区卡片 上下堆叠 */
.pci-side-col {
  display: flex;
  flex-direction: column;
  gap: var(--sim-gap);
  min-width: 0;
}

.pci-side-col .neighbor-card {
  flex: 1 1 auto;
}

/* 优选PCI小区: 配置项行 */
.sim-prefer-row {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  width: 100%;
}

.sim-prefer-input {
  width: 140px;
}

/* 优选卡片: 排除小区为可增删的条目列表 */
.sim-prefer-col {
  display: flex;
  flex-direction: column;
  gap: 8px;
  width: 100%;
}

/* 条目后的 +/− 圆形按钮, 固定尺寸不被压缩 */
.sim-prefer-icon-btn {
  flex: 0 0 auto;
}

.sim-prefer-hint {
  font-size: var(--sim-font-xs);
  color: var(--el-text-color-secondary);
}

/* 优选状态 / 探测轮次: 标签 + 徽章并排成组, 两组同处一行 */
.pci-prefer-status-group {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
  min-width: 0;
}

/* 探测结果标题: 文本样式与左侧表单标签(锁定方式)保持一致; 分割线由上方状态行提供, 此处不再重复绘制 */
.pci-prefer-subtitle {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 14px;
  padding-top: 12px;
  font-size: var(--sim-font-base);
  font-weight: 400;
  color: var(--el-text-color-regular);
}

/* 决策原因: 与「探测结果」同行, 靠右显示 */
.pci-prefer-reason {
  font-size: var(--sim-font-minor);
  font-weight: 600;
  color: var(--el-color-success);
}

/* 小区信息表格: 加一圈外框, 与上方状态行区分 */
.sim-cell-table {
  border: var(--sim-border);
  border-radius: var(--sim-radius-sm);
  padding: 6px 8px 2px;
  overflow: hidden;
}

/* 卡片: 一层浅边框 + 纯色底, 不使用渐变/投影/彩色装饰条 */
.config-card {
  border: var(--sim-border);
  border-radius: var(--sim-radius);
  background: var(--el-bg-color);
}

:deep(.config-card .el-card__header) {
  padding: 12px 16px 0;
  border-bottom: 0;
}

:deep(.config-card .el-card__body) {
  padding: 10px 16px 16px;
}

:deep(.compact-card .el-card__header) {
  padding: 12px 14px 0;
}

:deep(.compact-card .el-card__body) {
  padding: 8px 14px 14px;
  overflow: visible;
}

.compact-card .status-item {
  padding: 6px 0;
}

.compact-card .status-label {
  font-size: var(--sim-font-label);
}

.compact-card .status-value {
  font-size: var(--sim-font-label);
}

.neighbor-card {
  flex: 2;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.sim-card-title {
  font-size: var(--sim-font-base);
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.config-form {
  padding: 10px 0;
}

:deep(.basic-form .el-input),
:deep(.basic-form .el-select) {
  width: 20%;
}

:deep(.config-form .el-form-item) {
  margin-bottom: 14px;
}

:deep(.config-form .el-form-item:last-child) {
  margin-bottom: 0;
}

:deep(.config-form .el-form-item__label) {
  line-height: 32px;
  padding-bottom: 0;
}

:deep(.config-form .el-form-item__content) {
  min-height: 32px;
  align-items: center;
}

.status-info {
  padding: 10px 0;
}

.signal-row {
  display: flex;
  gap: 15px;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px solid var(--el-border-color-lighter);
  align-items: center;
}

.signal-row:last-child {
  border-bottom: none;
}

.signal-row-right {
  justify-content: flex-start;
}

.signal-row-right .signal-title {
  margin-right: auto;
}

.signal-row-right .signal-item {
  justify-content: flex-end;
  flex: 0 0 auto;
}

.signal-title {
  min-width: 80px;
  font-size: var(--sim-font-label);
  font-weight: 500;
  color: var(--el-text-color-regular);
}

.signal-item {
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: center;
  gap: 5px;
  flex: 1;
}

.signal-item .status-label {
  font-size: var(--sim-font-minor);
  color: var(--el-text-color-regular);
}

.signal-item .status-value {
  font-size: var(--sim-font-label);
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.status-table {
  display: flex;
  flex-direction: column;
  gap: 15px;
  padding: 10px 0;
}

.table-title {
  margin-bottom: 4px;
  text-align: center;
  font-size: var(--sim-font-label);
  font-weight: 600;
  color: var(--el-text-color-regular);
}

.table-row {
  display: flex;
  gap: 10px;
}

.header-row {
  border-bottom: 1px solid var(--el-border-color-lighter);
  padding-bottom: 5px;
  margin-bottom: 5px;
}

.table-cell {
  flex: 1;
  text-align: center;
  font-size: var(--sim-font-minor);
  padding: 5px 2px;
}

.signal-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 40px;
  height: 16px;
  padding: 0 6px;
  border-radius: 999px;
  font-size: var(--sim-font-xs);
  font-weight: 500;
  color: var(--el-color-white);
  white-space: nowrap;
  line-height: 1;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* 信号等级: 颜色只表达强弱, 取自 el 语义色板 */
.signal-badge.sig-excellent { background: var(--el-color-success); }
.signal-badge.sig-good      { background: var(--el-color-success-light-3); color: var(--el-text-color-primary); }
.signal-badge.sig-fair      { background: var(--el-color-warning); }
.signal-badge.sig-poor      { background: var(--el-color-danger); }
.signal-badge.sig-empty     { background: var(--el-fill-color); color: var(--el-text-color-secondary); }

.header-row .table-cell {
  font-weight: 600;
  color: var(--el-text-color-regular);
}

.cell-zh {
  font-weight: 600;
  color: var(--el-text-color-regular);
  line-height: 1.3;
}

.cell-en {
  margin-top: 2px;
  font-size: var(--sim-font-xs);
  font-weight: 400;
  color: var(--el-text-color-secondary);
  line-height: 1.2;
}

/* 数值单元格内的补充值, 如 PCI 的十进制: DF (223) */
.cell-sub {
  margin-left: 2px;
  font-size: var(--sim-font-xs);
  font-weight: 400;
  color: var(--el-text-color-secondary);
}

.table-row:not(.header-row) .table-cell {
  font-weight: 500;
  color: var(--el-text-color-primary);
}

.table-row:not(.header-row):hover,
.table-row:not(.header-row):hover .table-cell {
  background-color: var(--el-fill-color-light);
}

.no-data {
  text-align: center;
  padding: 20px;
  color: var(--el-text-color-secondary);
  font-size: var(--sim-font-label);
}

.status-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  padding: 10px 0;
  border-bottom: 1px solid var(--el-border-color-lighter);
}

.status-item:last-child {
  border-bottom: none;
}

.status-label {
  flex: 0 0 auto;
  font-size: var(--sim-font-base);
  font-weight: 400;
  color: var(--el-text-color-regular);
}

.status-value {
  min-width: 0;
  flex: 1 1 auto;
  text-align: right;
  font-weight: 600;
  overflow-wrap: anywhere;
  word-break: break-word;
}

/* 状态徽章: 底色/文字均取自 el 语义色板 */
.status-badge {
  display: inline-block;
  padding: 3px 12px;
  border-radius: 999px;
  font-size: var(--sim-font-minor);
  font-weight: 600;
  line-height: 1.6;
}

.status-badge-online {
  background: var(--el-color-success-light-9);
  color: var(--el-color-success);
}

.status-badge-noservice {
  background: var(--el-color-warning-light-9);
  color: var(--el-color-warning);
}

/* 优选状态: 优选进行中 / 执行完毕 */
.status-badge-running {
  background: var(--el-color-success-light-9);
  color: var(--el-color-success);
}

.status-badge-done {
  background: var(--el-color-info-light-9);
  color: var(--el-color-info);
}

.status-badge-nomodule {
  background: var(--el-color-danger-light-9);
  color: var(--el-color-danger);
}

.status-badge-offline {
  background: var(--el-color-danger-light-9);
  color: var(--el-color-danger);
}

.status-badge-disabled {
  background: var(--el-fill-color);
  color: var(--el-text-color-secondary);
}

.status-badge-info {
  background: var(--el-color-primary-light-9);
  color: var(--el-color-primary);
}

.card-actions {
  justify-content: flex-end;
}

.action-buttons {
  display: flex;
  justify-content: center;
  gap: 15px;
}

.sim-full-width {
  width: 100%;
}

.sim-inline-row {
  display: flex;
  gap: 12px;
  width: 100%;
}

.sim-inline-form-item {
  flex: 1;
}

.sim-inline-form-item,
.sim-lock-form-item,
.sim-switch-form-item {
  width: 100%;
}

.sim-inline-form-item :deep(.el-form-item__content),
.sim-lock-form-item :deep(.el-form-item__content),
.sim-switch-form-item :deep(.el-form-item__content) {
  width: 100%;
}

.sim-lock-section {
  display: flex;
  flex-direction: column;
  gap: var(--sim-gap);
  width: 100%;
  box-sizing: border-box;
  padding: 12px 14px;
  border: var(--sim-border);
  border-radius: var(--sim-radius);
  background: var(--el-fill-color-lighter);
}

.sim-lock-toggle {
  display: flex;
  align-items: center;
  gap: 8px;
}

.sim-pci-row {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
}

.sim-lock-toolbar {
  justify-content: flex-start;
  padding-bottom: 2px;
}

.sim-band-panel {
  box-sizing: border-box;
  padding: 10px 12px;
  border: var(--sim-border);
  border-radius: var(--sim-radius-sm);
  background: var(--el-bg-color);
}

.sim-pci-toolbar {
  justify-content: space-between;
  align-items: center;
  flex-wrap: nowrap;
  gap: var(--sim-gap);
  width: 100%;
  min-width: 0;
  box-sizing: border-box;
  padding: 8px 12px;
  border: var(--sim-border);
  border-radius: var(--sim-radius-sm);
  background: var(--el-bg-color);
}

/* 锁NR/LTE PCI: 开关行 */
.sim-lock-head {
  display: flex;
  align-items: center;
  gap: 8px;
}

.sim-lock-head-text {
  font-size: var(--sim-font-minor);
  color: var(--el-text-color-secondary);
}

/* 锁NR/LTE PCI: 条目表(去掉嵌套卡片, 仅用细线分隔) */
.sim-pci-table {
  display: flex;
  flex-direction: column;
  width: 100%;
  min-width: 0;
}

/* 列宽: NR 为5列(含子载波间隔), LTE 为4列 */
.sim-pci-table:not(.is-lte) {
  --sim-pci-cols: minmax(0, 1fr) minmax(0, 1fr) minmax(0, 0.9fr) minmax(0, 1.1fr) 48px;
}

.sim-pci-table.is-lte {
  --sim-pci-cols: minmax(0, 1fr) minmax(0, 1fr) minmax(0, 0.9fr) 48px;
}

.sim-pci-col-head,
.sim-pci-entry-row {
  display: grid;
  grid-template-columns: var(--sim-pci-cols);
  align-items: center;
  column-gap: 12px;
  width: 100%;
  min-width: 0;
}

.sim-pci-col-head {
  padding-bottom: 6px;
  border-bottom: var(--sim-border);
  font-size: var(--sim-font-minor);
  color: var(--el-text-color-secondary);
}

.sim-pci-entry-row {
  padding: 8px 0;
  border-bottom: var(--sim-border);
}

.sim-pci-entry-row:last-child {
  padding-bottom: 0;
  border-bottom: 0;
}

.sim-pci-meta {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.sim-pci-meta-title {
  font-size: var(--sim-font-label);
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.sim-pci-meta-desc {
  font-size: var(--sim-font-minor);
  line-height: 1.5;
  color: var(--el-text-color-secondary);
}

.sim-pci-add-btn {
  flex: 0 0 auto;
}

/* 锁NR/LTE PCI: 底部操作行(添加条目 + 允许重选切换) */
.sim-pci-foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  flex-wrap: wrap;
}

.sim-pci-foot-item {
  display: flex;
  align-items: center;
  gap: 8px;
}

.sim-pci-foot-label {
  font-size: var(--sim-font-minor);
  color: var(--el-text-color-regular);
}

.sim-switch-form-item {
  padding-top: 2px;
}

.sim-pci-input {
  width: 100%;
  min-width: 0;
  max-width: 100%;
}

.sim-pci-remove-btn {
  flex: 0 0 auto;
  justify-self: end;
  min-width: 0;
}

.band-option-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  min-height: 32px;
  align-items: center;
}

.band-option-tag {
  cursor: pointer;
  min-height: 30px;
  padding: 0 14px;
  border-radius: 999px;
  transition: color 0.15s ease, border-color 0.15s ease;
}

.band-option-tag:hover {
  color: var(--el-color-primary);
  border-color: var(--el-color-primary);
}

.band-option-empty {
  color: var(--el-text-color-secondary);
  font-size: var(--sim-font-minor);
  line-height: 1.6;
  padding: 2px 0;
}

:deep(.wan-enable-switch.el-switch:not(.is-checked) .el-switch__inner .is-text),
:deep(.wan-enable-switch:not(.is-checked) .el-switch__inner .is-text) {
  color: var(--el-color-danger);
}

:deep(.btn-disabled-warning.is-disabled) {
  background-color: var(--el-color-warning-light-7);
  border-color: var(--el-color-warning-light-5);
  color: var(--el-color-warning);
  opacity: 1;
}

@media (max-width: 1400px) {
  .status-tab-content {
    grid-template-columns: 1fr;
  }

  .pci-tab-grid {
    grid-template-columns: 1fr;
  }

  .status-card-grid {
    grid-template-columns: 1fr 1fr;
    grid-column: auto;
  }

  .at-log-card {
    grid-column: auto;
    align-self: auto;
  }

  :deep(.at-log-card .el-card__body) {
    position: static;
    height: 380px;
    display: flex;
    flex-direction: column;
  }

  .at-log-terminal {
    position: static;
    flex: 1;
    min-height: 0;
  }

  .at-log-actions {
    position: static;
    margin-top: 12px;
  }

  .signal-row {
    flex-wrap: wrap;
    row-gap: 8px;
  }

  .signal-title {
    flex: 1 0 100%;
    min-width: 0;
  }

  .signal-row-right .signal-title {
    margin-right: 0;
  }

  .signal-row-right .signal-item {
    justify-content: flex-start;
  }

  .sim-pci-table:not(.is-lte),
  .sim-pci-table.is-lte {
    --sim-pci-cols: repeat(2, minmax(0, 1fr));
  }

  /* 两列布局下输入框本身可辨识, 隐藏列名行避免列名与控件错位 */
  .sim-pci-col-head {
    display: none;
  }

  .sim-pci-remove-btn {
    grid-column: 1 / -1;
    justify-self: end;
  }
}

@media (max-width: 768px) {
  .status-card-grid {
    grid-template-columns: 1fr;
  }

  .resident-card {
    grid-column: auto;
  }

  .status-side-col {
    grid-template-columns: 1fr;
  }

  .action-buttons {
    flex-direction: column;
    align-items: center;
  }

  .action-buttons .el-button {
    width: 200px;
  }

  .sim-inline-row,
  .sim-pci-row {
    flex-direction: column;
    align-items: stretch;
  }

  .sim-lock-section {
    padding: 12px;
  }

  .sim-pci-table:not(.is-lte),
  .sim-pci-table.is-lte {
    --sim-pci-cols: 1fr;
  }

  .sim-pci-entry-row {
    padding: 10px 0;
  }

  .sim-pci-toolbar {
    padding: 10px;
    flex-wrap: wrap;
    align-items: stretch;
  }

  .sim-pci-foot {
    flex-direction: column;
    align-items: stretch;
  }

  .sim-pci-foot-item {
    justify-content: space-between;
  }

  .sim-pci-add-btn {
    width: 100%;
  }

  .sim-pci-remove-btn {
    justify-self: end;
  }
}

/* AT日志: 深色终端配色集中在此定义, 深底不随主题变化, 故不复用 el 文本色 */
.at-log-card {
  --sim-term-bg: #1e1e1e;
  --sim-term-fg: #cbd5e1;
  --sim-term-dim: #94a3b8;
  --sim-term-res-bg: rgba(255, 255, 255, 0.04);
  --sim-term-divider: rgba(255, 255, 255, 0.06);
  --sim-term-line: rgba(255, 255, 255, 0.12);
  /* 位于实时状态页网格右下角 */
  grid-column: 2;
  /* 与左侧锁频状态卡片等高 */
  align-self: stretch;
  display: flex;
  flex-direction: column;
}

:deep(.at-log-card .el-card__body) {
  position: relative;
  flex: 1;
  min-height: 0;
}

.at-log-actions {
  position: absolute;
  left: 0;
  right: 0;
  bottom: 8px;
  display: flex;
  justify-content: center;
  margin-top: 0;
}

.at-log-terminal {
  position: absolute;
  top: 8px;
  left: 14px;
  right: 14px;
  bottom: 40px;
  background: var(--sim-term-bg);
  border-radius: var(--sim-radius-sm);
  padding: 10px 14px;
  overflow-y: auto;
  font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
  font-size: var(--sim-font-minor);
  line-height: 1.6;
}

.at-log-empty {
  color: var(--sim-term-dim);
  text-align: center;
  padding: 20px 0;
}

.at-log-entry {
  padding: 10px 0;
  border-bottom: 1px solid var(--sim-term-divider);
}

.at-log-entry:last-child {
  border-bottom: none;
}

.at-log-entry-head {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 6px;
  font-size: var(--sim-font-xs);
  color: var(--sim-term-dim);
}

.at-log-seq {
  color: var(--el-color-warning-light-3);
}

.at-log-ts {
  color: var(--sim-term-fg);
}

.at-log-tty {
  color: var(--el-color-primary-light-3);
}

.at-log-line {
  color: var(--sim-term-dim);
  word-break: break-all;
  white-space: pre-wrap;
}

.at-log-cmd {
  color: var(--el-color-primary-light-3);
  font-weight: 600;
}

.at-log-res {
  margin: 0;
  font: inherit;
  color: var(--sim-term-fg);
  background: var(--sim-term-res-bg);
  border-radius: var(--sim-radius-sm);
  padding: 8px 10px;
}

.at-log-res.is-ok {
  color: var(--el-color-success-light-3);
}

.at-log-res.is-err {
  color: var(--el-color-danger-light-3);
}

.at-log-gap {
  color: var(--el-color-warning-light-3);
  background: var(--sim-term-res-bg);
  border: 1px solid var(--sim-term-line);
  border-radius: var(--sim-radius-sm);
  padding: 8px 10px;
}
</style>

<style>
/* 优选PCI小区提示弹层: 弹层挂载在 body 上, scoped 样式命中不到, 故单独用全局样式块 */
.sim-prefer-tip-popper.el-popper.is-light {
  background: var(--el-bg-color-overlay);
  border: 1px solid var(--el-color-danger);
  color: var(--el-color-danger);
}

.sim-prefer-tip-popper.el-popper.is-light .el-popper__arrow::before {
  background: var(--el-bg-color-overlay);
  border-color: var(--el-color-danger);
}
</style>

<i18n src="./locale.json"/>
