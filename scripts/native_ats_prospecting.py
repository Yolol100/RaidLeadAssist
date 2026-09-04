from __future__ import annotations

import argparse
import ipaddress
import json
import re
import socket
import sys
from collections import defaultdict
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlparse, urlunparse
from urllib.request import HTTPRedirectHandler, Request, build_opener

MAX_RESPONSE_BYTES = 5_000_000
MAX_SOURCES = 500
SUPPORTED_PROVIDERS = {"greenhouse", "lever", "ashby", "smartrecruiters", "recruitee"}
USER_AGENT = "WebactueelLeadKernel/1.0 (+https://andrewbaeten.nl)"


@dataclass(frozen=True)
class SourceSpec:
    provider: str
    account: str
    company_name: str
    company_website: str
    country: str = ""

    @classmethod
    def from_dict(cls, raw: dict[str, Any]) -> "SourceSpec":
        required = ("provider", "account", "company_name", "company_website")
        missing = [key for key in required if not str(raw.get(key, "")).strip()]
        if missing:
            raise ValueError("source is missing: " + ", ".join(missing))
        provider = str(raw["provider"]).strip().lower()
        if provider not in SUPPORTED_PROVIDERS:
            raise ValueError(
                f"unsupported provider {provider!r}; supported: {', '.join(sorted(SUPPORTED_PROVIDERS))}"
            )
        return cls(
            provider=provider,
            account=str(raw["account"]).strip(),
            company_name=str(raw["company_name"]).strip(),
            company_website=str(raw["company_website"]).strip(),
            country=str(raw.get("country", "")).strip(),
        )


@dataclass(frozen=True)
class JobSignal:
    provider: str
    company_name: str
    company_website: str
    country: str
    title: str
    location: str
    job_url: str
    published_at: str
    source_url: str


class SafeRedirectHandler(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):  # type: ignore[override]
        validate_public_https_url(newurl)
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def utc_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def clean_text(value: object) -> str:
    text = re.sub(r"<[^>]+>", " ", str(value or ""))
    return re.sub(r"\s+", " ", text).strip()


def normalize_date(value: object) -> str:
    if isinstance(value, (int, float)):
        seconds = float(value) / 1000 if float(value) > 10_000_000_000 else float(value)
        try:
            return datetime.fromtimestamp(seconds, timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
        except (OverflowError, OSError, ValueError):
            return str(value)
    raw = str(value or "").strip()
    if not raw:
        return ""
    try:
        parsed = datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        return raw
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def canonical_website(value: str) -> str:
    value = value.strip()
    if not value.startswith(("https://", "http://")):
        value = "https://" + value
    parsed = urlparse(value)
    if parsed.scheme not in {"http", "https"} or not parsed.hostname:
        raise ValueError(f"invalid website: {value}")
    host = parsed.hostname.lower().rstrip(".")
    if host.startswith("www."):
        host = host[4:]
    return urlunparse(("https", host, "/", "", "", ""))


def domain_key(value: str) -> str:
    return urlparse(canonical_website(value)).hostname or ""


def validate_public_https_url(url: str) -> str:
    parsed = urlparse(url)
    if parsed.scheme != "https" or not parsed.hostname:
        raise ValueError("only public HTTPS URLs are allowed")
    host = parsed.hostname.rstrip(".").lower()
    if host in {"localhost", "localhost.localdomain"} or host.endswith(".local"):
        raise ValueError("local hosts are not allowed")
    try:
        addresses = {item[4][0] for item in socket.getaddrinfo(host, parsed.port or 443)}
    except socket.gaierror as exc:
        raise ValueError(f"hostname could not be resolved: {host}") from exc
    if not addresses:
        raise ValueError(f"hostname did not resolve: {host}")
    for value in addresses:
        if not ipaddress.ip_address(value).is_global:
            raise ValueError(f"non-public address is not allowed: {host}")
    return url


def get_json(url: str, *, timeout: int = 20) -> Any:
    validate_public_https_url(url)
    request = Request(url, headers={"Accept": "application/json", "User-Agent": USER_AGENT})
    try:
        with build_opener(SafeRedirectHandler()).open(request, timeout=timeout) as response:
            validate_public_https_url(response.geturl())
            raw = response.read(MAX_RESPONSE_BYTES + 1)
    except (HTTPError, URLError, TimeoutError) as exc:
        raise RuntimeError(f"GET failed for {url}: {exc}") from exc
    if len(raw) > MAX_RESPONSE_BYTES:
        raise RuntimeError(f"response exceeded {MAX_RESPONSE_BYTES} bytes")
    try:
        return json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"invalid JSON from {url}") from exc


def fetch_greenhouse(source: SourceSpec, max_jobs: int) -> list[JobSignal]:
    endpoint = f"https://boards-api.greenhouse.io/v1/boards/{quote(source.account)}/jobs"
    payload = get_json(endpoint + "?content=true")
    jobs = payload.get("jobs", []) if isinstance(payload, dict) else []
    result = []
    for job in jobs[:max_jobs]:
        location = job.get("location", {})
        result.append(JobSignal(
            source.provider, source.company_name, source.company_website, source.country,
            clean_text(job.get("title")),
            clean_text(location.get("name") if isinstance(location, dict) else location),
            str(job.get("absolute_url", "")).strip(), normalize_date(job.get("updated_at")), endpoint,
        ))
    return result


def fetch_lever(source: SourceSpec, max_jobs: int) -> list[JobSignal]:
    endpoint = f"https://api.lever.co/v0/postings/{quote(source.account)}?mode=json"
    payload = get_json(endpoint)
    jobs = payload if isinstance(payload, list) else []
    result = []
    for job in jobs[:max_jobs]:
        categories = job.get("categories", {})
        result.append(JobSignal(
            source.provider, source.company_name, source.company_website, source.country,
            clean_text(job.get("text")),
            clean_text(categories.get("location") if isinstance(categories, dict) else ""),
            str(job.get("hostedUrl") or job.get("applyUrl") or "").strip(),
            normalize_date(job.get("createdAt")), endpoint,
        ))
    return result


def fetch_ashby(source: SourceSpec, max_jobs: int) -> list[JobSignal]:
    endpoint = f"https://api.ashbyhq.com/posting-api/job-board/{quote(source.account)}"
    payload = get_json(endpoint)
    jobs = payload.get("jobs", []) if isinstance(payload, dict) else []
    return [JobSignal(
        source.provider, source.company_name, source.company_website, source.country,
        clean_text(job.get("title")), clean_text(job.get("location")),
        str(job.get("jobUrl") or job.get("applyUrl") or "").strip(),
        normalize_date(job.get("publishedAt")), endpoint,
    ) for job in jobs[:max_jobs]]


def fetch_smartrecruiters(source: SourceSpec, max_jobs: int) -> list[JobSignal]:
    endpoint = f"https://api.smartrecruiters.com/v1/companies/{quote(source.account)}/postings"
    payload = get_json(endpoint + f"?limit={min(max_jobs, 100)}")
    jobs = payload.get("content", []) if isinstance(payload, dict) else []
    result = []
    for job in jobs[:max_jobs]:
        location = job.get("location", {})
        location_text = ", ".join(
            clean_text(location.get(key)) for key in ("city", "region", "country")
            if isinstance(location, dict) and location.get(key)
        )
        result.append(JobSignal(
            source.provider, source.company_name, source.company_website, source.country,
            clean_text(job.get("name")), location_text, str(job.get("ref") or "").strip(),
            normalize_date(job.get("releasedDate")), endpoint,
        ))
    return result


def fetch_recruitee(source: SourceSpec, max_jobs: int) -> list[JobSignal]:
    account = source.account.lower().strip()
    if not re.fullmatch(r"[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?", account):
        raise ValueError("invalid Recruitee account subdomain")
    endpoint = f"https://{account}.recruitee.com/api/offers"
    payload = get_json(endpoint)
    jobs = payload.get("offers", []) if isinstance(payload, dict) else []
    return [JobSignal(
        source.provider, source.company_name, source.company_website, source.country,
        clean_text(job.get("title")), clean_text(job.get("location")),
        str(job.get("careers_url") or job.get("url") or "").strip(),
        normalize_date(job.get("published_at")), endpoint,
    ) for job in jobs[:max_jobs]]


FETCHERS = {
    "greenhouse": fetch_greenhouse,
    "lever": fetch_lever,
    "ashby": fetch_ashby,
    "smartrecruiters": fetch_smartrecruiters,
    "recruitee": fetch_recruitee,
}


def date_key(value: str) -> datetime:
    try:
        parsed = datetime.fromisoformat((value or "").replace("Z", "+00:00"))
    except ValueError:
        return datetime.min.replace(tzinfo=timezone.utc)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def collect(sources: list[SourceSpec], max_jobs: int) -> list[JobSignal]:
    signals: list[JobSignal] = []
    for source in sources:
        signals.extend(FETCHERS[source.provider](source, max_jobs))
    return signals


def aggregate(signals: list[JobSignal], output_limit: int) -> list[dict[str, Any]]:
    grouped: dict[str, list[JobSignal]] = defaultdict(list)
    for signal in signals:
        grouped[domain_key(signal.company_website)].append(signal)
    candidates = []
    for company_signals in grouped.values():
        company_signals.sort(key=lambda item: date_key(item.published_at), reverse=True)
        strongest = company_signals[0]
        count = len(company_signals)
        candidates.append({
            "schema_version": "webactueel.prospect-candidate.v1",
            "company_name": strongest.company_name,
            "website": canonical_website(strongest.company_website),
            "country": strongest.country,
            "lead_source_type": "ats_public",
            "source_provider": strongest.provider,
            "source_url": strongest.source_url,
            "trigger_type": "active_hiring",
            "trigger_date": strongest.published_at,
            "trigger_evidence": f"{count} openbare vacature{'s' if count != 1 else ''}; meest recente: {strongest.title}",
            "trigger_strength": "medium",
            "job_title": strongest.title,
            "job_location": strongest.location,
            "job_url": strongest.job_url,
            "discovered_at": utc_iso(),
            "requires_official_site_verification": True,
            "requires_contact_verification": True,
            "requires_compliance_review": True,
        })
    candidates.sort(key=lambda item: (date_key(str(item["trigger_date"])), str(item["company_name"]).lower()), reverse=True)
    return candidates[:output_limit]


def load_sources(path: str | None, inline_json: str | None) -> list[SourceSpec]:
    if bool(path) == bool(inline_json):
        raise ValueError("provide exactly one of --sources or --sources-json")
    raw = json.loads(Path(path).read_text(encoding="utf-8") if path else str(inline_json))
    if not isinstance(raw, list):
        raise ValueError("sources must be a JSON array")
    if len(raw) > MAX_SOURCES:
        raise ValueError(f"at most {MAX_SOURCES} sources are allowed")
    return [SourceSpec.from_dict(item) for item in raw]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Collect public ATS hiring signals for Leads review")
    parser.add_argument("--sources")
    parser.add_argument("--sources-json")
    parser.add_argument("--output", default="prospect-candidates.json")
    parser.add_argument("--max-jobs-per-source", type=int, default=100)
    parser.add_argument("--output-limit", type=int, default=100)
    args = parser.parse_args(argv)
    if not 1 <= args.max_jobs_per_source <= 500:
        parser.error("--max-jobs-per-source must be 1..500")
    if not 1 <= args.output_limit <= 1000:
        parser.error("--output-limit must be 1..1000")
    try:
        sources = load_sources(args.sources, args.sources_json)
        signals = collect(sources, args.max_jobs_per_source)
        candidates = aggregate(signals, args.output_limit)
    except (ValueError, RuntimeError, json.JSONDecodeError) as exc:
        print(f"lead-kernel error: {exc}", file=sys.stderr)
        return 2
    output = Path(args.output)
    output.write_text(json.dumps(candidates, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"sources={len(sources)} signals={len(signals)} candidates={len(candidates)} output={output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
