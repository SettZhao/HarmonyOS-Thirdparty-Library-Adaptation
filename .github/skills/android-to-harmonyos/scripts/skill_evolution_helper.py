#!/usr/bin/env python3
"""
Skill 自进化辅助工具

功能：
1. 验证 SKILL.md 格式
2. 检查模板文件中的待处理内容
3. 生成更新报告
4. 辅助将模板内容合并到正式文档

用法：
  python skill_evolution_helper.py --check        # 检查待处理内容
  python skill_evolution_helper.py --validate     # 验证文档格式
  python skill_evolution_helper.py --report       # 生成更新报告
  python skill_evolution_helper.py --merge        # 交互式合并模板到正式文档
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path
from datetime import datetime


class SkillEvolutionHelper:
    def __init__(self, skill_dir: Path):
        self.skill_dir = skill_dir
        self.skill_md = skill_dir / "SKILL.md"
        self.api_template = skill_dir / "API_MAPPING_TEMPLATE.md"
        self.issues_template = skill_dir / "ISSUES_TEMPLATE.md"
        self.api_mapping_md = skill_dir / "references" / "api-mapping.md"
    
    def check_pending(self) -> dict:
        """检查模板文件中的待处理内容"""
        print("🔍 检查待处理内容...\n")
        
        pending = {
            "api_mappings": [],
            "issues": [],
            "new_refs": []
        }
        
        # 检查 API 映射模板
        if self.api_template.exists():
            content = self.api_template.read_text(encoding='utf-8')
            
            # 查找非空的表格行（排除示例行）
            table_pattern = r'\|\s*(?!<!--)[^\|]+\|[^\|]+\|[^\|]+\|[^\|]+\|'
            matches = re.findall(table_pattern, content)
            
            if matches:
                print(f"📋 API 映射模板：发现 {len(matches)} 条待添加映射")
                pending["api_mappings"] = matches[:3]  # 只显示前3条
                if len(matches) > 3:
                    print(f"   （省略 {len(matches) - 3} 条...）")
            else:
                print("📋 API 映射模板：无待处理内容 ✅")
            
            # 检查待创建详细文档
            if "待创建详细文档" in content:
                new_refs_section = content.split("待创建详细文档")[1].split("---")[0]
                ref_matches = re.findall(r'### 模块名：`([^`]+)`', new_refs_section)
                if ref_matches:
                    print(f"📚 待创建详细文档：{len(ref_matches)} 个模块")
                    pending["new_refs"] = ref_matches
                    for ref in ref_matches:
                        print(f"   - {ref}")
        
        print()
        
        # 检查问题模板
        if self.issues_template.exists():
            content = self.issues_template.read_text(encoding='utf-8')
            
            # 查找未处理的问题（在"待处理问题"部分）
            if "## 待处理问题" in content:
                pending_section = content.split("## 待处理问题")[1].split("## 已解决问题")[0]
                issue_matches = re.findall(r'### 问题 #\d+: \[(.+?)\]', pending_section)
                
                if issue_matches and issue_matches[0] != "问题简要描述":
                    print(f"⚠️  问题模板：发现 {len(issue_matches)} 个待处理问题")
                    pending["issues"] = issue_matches
                    for idx, issue in enumerate(issue_matches, 1):
                        print(f"   {idx}. {issue}")
                else:
                    print("⚠️  问题模板：无待处理内容 ✅")
        
        print()
        return pending
    
    def validate_skill(self) -> bool:
        """验证 SKILL.md 格式"""
        print("✅ 验证 SKILL.md 格式...\n")
        
        if not self.skill_md.exists():
            print("❌ SKILL.md 不存在")
            return False
        
        content = self.skill_md.read_text(encoding='utf-8')
        is_valid = True
        
        # 检查必要章节
        required_sections = [
            "# Android 三方库移植 OpenHarmony",
            "## 移植工作流",
            "## Step 1: 分析库的可移植性",
            "## Step 2: 确定库类型和移植策略",
            "## Step 3: 创建 OpenHarmony 项目结构",
            "## Step 4: 迁移核心代码",
            "## Step 5: 构建、测试与发布",
            "## ⚠️ 关键注意事项"
        ]
        
        for section in required_sections:
            if section not in content:
                print(f"❌ 缺少章节: {section}")
                is_valid = False
            else:
                print(f"✅ {section}")
        
        print()
        
        # 检查代码块闭合
        code_blocks = re.findall(r'```', content)
        if len(code_blocks) % 2 != 0:
            print("❌ 代码块未正确闭合")
            is_valid = False
        else:
            print(f"✅ 代码块闭合正确 ({len(code_blocks) // 2} 个代码块)")
        
        print()
        
        # 统计关键注意事项数量
        attention_items = re.findall(r'### \d+\. \*\*', content)
        print(f"📌 关键注意事项：{len(attention_items)} 条")
        
        return is_valid
    
    def generate_report(self) -> None:
        """生成更新报告"""
        print("📊 生成 Skill 更新报告\n")
        print("=" * 60)
        print(f"报告日期：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 60)
        print()
        
        # 检查待处理内容
        pending = self.check_pending()
        
        # 统计文档信息
        if self.skill_md.exists():
            content = self.skill_md.read_text(encoding='utf-8')
            lines = len(content.split('\n'))
            code_blocks = len(re.findall(r'```', content)) // 2
            attention_items = len(re.findall(r'### \d+\. \*\*', content))
            
            print("📄 SKILL.md 统计")
            print(f"   总行数：{lines}")
            print(f"   代码块：{code_blocks}")
            print(f"   关键注意事项：{attention_items}")
            print()
        
        # 统计 refs 文档
        refs_dir = self.skill_dir / "references" / "refs"
        if refs_dir.exists():
            ref_files = list(refs_dir.glob("*.md"))
            print(f"📚 详细 API 参考：{len(ref_files)} 个文档")
            for ref_file in ref_files:
                print(f"   - {ref_file.stem}")
            print()
        
        # 待处理汇总
        print("📋 待处理汇总")
        total_pending = len(pending["api_mappings"]) + len(pending["issues"]) + len(pending["new_refs"])
        if total_pending > 0:
            print(f"   ⚠️  共 {total_pending} 项待处理")
            print(f"      - API 映射：{len(pending['api_mappings'])}")
            print(f"      - 问题记录：{len(pending['issues'])}")
            print(f"      - 待创建文档：{len(pending['new_refs'])}")
        else:
            print("   ✅ 无待处理内容")
        
        print()
        print("=" * 60)
    
    def interactive_merge(self) -> None:
        """交互式合并模板到正式文档"""
        print("🔄 交互式合并模板内容\n")
        print("此功能将帮助您将模板中的内容合并到正式文档。")
        print("请手动完成以下操作：\n")
        
        pending = self.check_pending()
        
        if pending["api_mappings"]:
            print("📋 合并 API 映射：")
            print(f"   1. 打开 {self.api_template}")
            print(f"   2. 复制待添加的映射行")
            print(f"   3. 粘贴到 {self.api_mapping_md} 对应分类下")
            print(f"   4. 清空模板文件中已处理的内容")
            print()
        
        if pending["issues"]:
            print("⚠️  合并问题记录：")
            print(f"   1. 打开 {self.issues_template}")
            print(f"   2. 评估每个问题是否需要添加到 SKILL.md")
            print(f"   3. 按照 EVOLUTION.md 中的格式添加到 SKILL.md")
            print(f"   4. 将已处理的问题移到「已解决问题」部分")
            print()
        
        if pending["new_refs"]:
            print("📚 创建详细文档：")
            print("   对于每个待创建的模块文档：")
            for ref in pending["new_refs"]:
                print(f"   - 创建 references/refs/{ref.replace('@', '').replace('.', '_')}.md")
            print()


def main():
    parser = argparse.ArgumentParser(
        description="Skill 自进化辅助工具",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例：
  python skill_evolution_helper.py --check
  python skill_evolution_helper.py --validate
  python skill_evolution_helper.py --report
  python skill_evolution_helper.py --merge
        """
    )
    
    parser.add_argument(
        '--check',
        action='store_true',
        help='检查模板文件中的待处理内容'
    )
    
    parser.add_argument(
        '--validate',
        action='store_true',
        help='验证 SKILL.md 格式'
    )
    
    parser.add_argument(
        '--report',
        action='store_true',
        help='生成详细的更新报告'
    )
    
    parser.add_argument(
        '--merge',
        action='store_true',
        help='交互式合并模板到正式文档'
    )
    
    parser.add_argument(
        '--skill-dir',
        type=Path,
        default=None,
        help='Skill 目录路径（默认：自动检测）'
    )
    
    args = parser.parse_args()
    
    # 如果没有指定任何操作，显示帮助
    if not (args.check or args.validate or args.report or args.merge):
        parser.print_help()
        return
    
    # 智能检测 skill 目录
    if args.skill_dir is None:
        script_dir = Path(__file__).parent
        # 脚本在 scripts/ 子目录中，向上一层是 skill 目录
        skill_dir = script_dir.parent
        # 验证是否是有效的 skill 目录
        if not (skill_dir / "SKILL.md").exists():
            print("❌ 无法自动检测 skill 目录，请使用 --skill-dir 参数指定")
            sys.exit(1)
    else:
        skill_dir = args.skill_dir
    
    # 创建辅助工具实例
    helper = SkillEvolutionHelper(skill_dir)
    
    # 执行相应操作
    if args.check:
        helper.check_pending()
    
    if args.validate:
        is_valid = helper.validate_skill()
        sys.exit(0 if is_valid else 1)
    
    if args.report:
        helper.generate_report()
    
    if args.merge:
        helper.interactive_merge()


if __name__ == "__main__":
    main()
